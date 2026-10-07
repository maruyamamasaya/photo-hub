import base64
import json
from datetime import datetime, timedelta, timezone
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import app

OWNER = '11111111-1111-4111-8111-111111111111'
PHOTO = '22222222-2222-4222-8222-222222222222'
KEY = f'users/{OWNER}/photos/{PHOTO}/original'

class APItests(unittest.TestCase):
    def setUp(self):
        os.environ.update(OWNER_SUB=OWNER, BUCKET='private-test')
        app._s3 = Mock()
        app._s3.generate_presigned_url.return_value = 'https://example.invalid/signed'
        def head(**kwargs):
            if '/tombstones/' in kwargs['Key']:
                missing = Exception(); missing.response = {'Error': {'Code': '404'}}; raise missing
            return {'ContentLength': 42, 'ChecksumSHA256': base64.b64encode(bytes(32)).decode()}
        app._s3.head_object.side_effect = head
    def request(self, body, owner=OWNER):
        claims = {} if owner is None else {'sub': owner}
        return app.handler({'requestContext': {'authorizer': {'jwt': {'claims': claims}}}, 'body': json.dumps(body)}, None)
    def test_owner_and_auth_required(self):
        for owner, expected in [(None, 401), ('other', 403)]:
            self.assertEqual(self.request({'key': KEY, 'action': 'get'}, owner)['statusCode'], expected)
        app._s3.generate_presigned_url.assert_not_called()
    def test_arbitrary_key_rejected(self):
        for key in [KEY.replace(OWNER, PHOTO), f'users/{OWNER}/../secret', f'users/{OWNER}/photos/{PHOTO}/bad', f'users/{OWNER}/backups/evil.json']:
            self.assertEqual(self.request({'key': key, 'action': 'get'})['statusCode'], 400)
    def test_put_checksum_condition_and_expiry(self):
        body = {'key': KEY, 'action': 'put', 'mime': 'image/heic', 'bytes': 42, 'checksum': base64.b64encode(bytes(32)).decode()}
        self.assertEqual(self.request(body)['statusCode'], 200)
        params = app._s3.generate_presigned_url.call_args.kwargs
        self.assertEqual(params['ExpiresIn'], 300)
        self.assertEqual(params['Params']['IfNoneMatch'], '*')
        self.assertEqual(params['Params']['ContentLength'], 42)
        body['checksum'] = 'bad'
        self.assertEqual(self.request(body)['statusCode'], 400)
    def test_latest_can_replace_but_snapshots_cannot(self):
        body = {'key': f'users/{OWNER}/backups/latest.json', 'action': 'put', 'mime': 'application/json', 'bytes': 42, 'checksum': base64.b64encode(bytes(32)).decode()}
        self.assertEqual(self.request(body)['statusCode'], 200)
        self.assertNotIn('IfNoneMatch', app._s3.generate_presigned_url.call_args.kwargs['Params'])
        self.assertEqual(self.request({'key': body['key'], 'action': 'delete'})['statusCode'], 400)
    def test_head_missing_vs_service_failure(self):
        missing = Exception(); missing.response = {'Error': {'Code': '404'}}
        app._s3.head_object.side_effect = missing
        result = self.request({'key': KEY, 'action': 'head'})
        self.assertEqual(json.loads(result['body']), {'exists': False})
        app._s3.head_object.side_effect = RuntimeError('network')
        self.assertEqual(self.request({'key': KEY, 'action': 'head'})['statusCode'], 502)
    def test_delete_idempotent_and_prefix_limited(self):
        app._s3.head_object.side_effect = lambda **kw: {'LastModified': datetime.now(timezone.utc) - timedelta(seconds=400)}
        for _ in range(2): self.assertEqual(self.request({'key': KEY, 'action': 'delete'})['statusCode'], 200)
        self.assertEqual(app._s3.delete_object.call_args.kwargs, {'Bucket': 'private-test', 'Key': KEY})
    def test_tombstone_blocks_signing_and_drains_existing_grants(self):
        app._s3.head_object.side_effect = lambda **kw: {'LastModified': datetime.now(timezone.utc)}
        self.assertEqual(self.request({'key': KEY, 'action': 'put'})['statusCode'], 410)
        self.assertEqual(self.request({'key': KEY, 'action': 'get'})['statusCode'], 410)
        self.assertEqual(self.request({'key': KEY, 'action': 'delete'})['statusCode'], 409)
        app._s3.delete_object.assert_not_called()
    def test_size_and_kind_limits(self):
        body = {'key': KEY.replace('original', 'thumbnail.jpg'), 'action': 'put', 'mime': 'image/heic', 'bytes': 42, 'checksum': base64.b64encode(bytes(32)).decode()}
        self.assertEqual(self.request(body)['statusCode'], 400)
        body.update(mime='image/jpeg', bytes=101 * 1024 * 1024)
        self.assertEqual(self.request(body)['statusCode'], 400)

if __name__ == '__main__': unittest.main()
