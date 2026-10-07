"""Personal authenticated S3 signing API; deploy behind API Gateway JWT authorizer."""
import base64
import json
import os
from datetime import datetime, timezone
from uuid import UUID

_s3 = None
KINDS = {'original', 'thumbnail.jpg', 'display.jpg'}
MIMES = {'image/heic', 'image/heif', 'image/jpeg', 'image/png', 'application/json'}


def client():
    global _s3
    if _s3 is None:
        import boto3
        from botocore.config import Config
        _s3 = boto3.client('s3', config=Config(signature_version='s3v4'))
    return _s3


def valid_id(value):
    try:
        return str(UUID(value)) == value
    except (ValueError, TypeError, AttributeError):
        return False


def validate_key(key, owner):
    if not isinstance(key, str) or not key.startswith(f'users/{owner}/'):
        raise ValueError('Invalid object key')
    parts = key.split('/')
    photo = len(parts) == 5 and parts[2] == 'photos' and valid_id(parts[3]) and parts[4] in KINDS
    backup = len(parts) == 4 and parts[2] == 'backups' and (parts[3] == 'latest.json' or (parts[3].endswith('.json') and valid_id(parts[3][:-5])))
    if not (photo or backup):
        raise ValueError('Invalid object key')
    return key


def response(status, body):
    return {'statusCode': status, 'headers': {'Content-Type': 'application/json', 'Cache-Control': 'no-store'}, 'body': json.dumps(body)}


def handler(event, context):
    owner = os.environ.get('OWNER_SUB', '')
    bucket = os.environ.get('BUCKET', '')
    if not valid_id(owner) or not bucket:
        return response(503, {'error': 'Service configuration incomplete'})
    claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
    if not claims.get('sub'):
        return response(401, {'error': 'Authentication required'})
    if claims['sub'] != owner:
        return response(403, {'error': 'Owner only'})
    try:
        raw = event.get('body') or '{}'
        if event.get('isBase64Encoded'):
            raw = base64.b64decode(raw, validate=True).decode('utf-8')
        if len(raw) > 8192:
            raise ValueError('Request too large')
        body = json.loads(raw)
        if not isinstance(body, dict):
            raise ValueError('Invalid JSON object')
        key = validate_key(body.get('key'), owner)
        action = body.get('action')
        if action not in {'head', 'put', 'get', 'delete'}:
            raise ValueError('Invalid action')
        s3 = client()
        params = {'Bucket': bucket, 'Key': key}
        if '/photos/' in key:
            photo_id = key.split('/')[3]
            tombstone_key = f'users/{owner}/tombstones/{photo_id}.json'
            try:
                marker = s3.head_object(Bucket=bucket, Key=tombstone_key)
            except Exception as exc:
                code = getattr(exc, 'response', {}).get('Error', {}).get('Code')
                if code not in {'404', 'NoSuchKey', 'NotFound'}:
                    raise
                marker = None
            if action == 'delete':
                if marker is None:
                    try:
                        s3.put_object(Bucket=bucket, Key=tombstone_key, Body=b'{}', ContentType='application/json', IfNoneMatch='*')
                    except Exception as exc:
                        if getattr(exc, 'response', {}).get('Error', {}).get('Code') not in {'PreconditionFailed', '412'}:
                            raise
                    marker = s3.head_object(Bucket=bucket, Key=tombstone_key)
                age = (datetime.now(timezone.utc) - marker['LastModified']).total_seconds()
                # Existing PUT grants can finish until expiration. Drain them before deletion.
                if age < 360:
                    return response(409, {'error': 'Deletion pending: retry after 6 minutes', 'retryAfter': max(1, int(360 - age))})
            elif marker is not None:
                return response(410, {'error': 'Photo is being deleted'})
        if action == 'head':
            try:
                info = s3.head_object(**params, ChecksumMode='ENABLED')
            except Exception as exc:
                code = getattr(exc, 'response', {}).get('Error', {}).get('Code')
                if code in {'404', 'NoSuchKey', 'NotFound'}:
                    return response(200, {'exists': False})
                raise
            return response(200, {'exists': True, 'bytes': info['ContentLength'], 'checksum': info.get('ChecksumSHA256', '')})
        if action == 'delete':
            # latest pointers and normal snapshots are kept; photo deletion only.
            if '/photos/' not in key:
                raise ValueError('Backup deletion is not exposed')
            s3.delete_object(**params)
            return response(200, {'deleted': True})
        if action == 'put':
            mime = body.get('mime')
            checksum = body.get('checksum')
            size = body.get('bytes')
            if mime not in MIMES or not isinstance(checksum, str):
                raise ValueError('Invalid content metadata')
            if len(base64.b64decode(checksum, validate=True)) != 32:
                raise ValueError('Invalid SHA256')
            if type(size) is not int or size <= 0 or size > 100 * 1024 * 1024:
                raise ValueError('Object size must be 1 byte to 100 MB')
            expected = 'application/json' if '/backups/' in key else ('image/jpeg' if not key.endswith('/original') else mime)
            if mime != expected or (key.endswith('/original') and mime == 'application/json'):
                raise ValueError('Invalid type for object kind')
            params.update(ContentType=mime, ChecksumSHA256=checksum, ContentLength=size)
            if not key.endswith('/backups/latest.json'):
                params['IfNoneMatch'] = '*'
            url = s3.generate_presigned_url('put_object', Params=params, ExpiresIn=300, HttpMethod='PUT')
        else:
            url = s3.generate_presigned_url('get_object', Params=params, ExpiresIn=300, HttpMethod='GET')
        return response(200, {'url': url, 'expiresIn': 300})
    except (ValueError, TypeError, UnicodeError):
        return response(400, {'error': 'Invalid request'})
    except Exception:
        # No signed URLs, credentials, or exception bodies in logs/responses.
        return response(502, {'error': 'Storage operation failed'})
