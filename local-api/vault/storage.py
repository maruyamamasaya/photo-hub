import hashlib
from pathlib import Path


class AssetStorage:
    def __init__(self, root):
        self.root = Path(root).resolve()
        self.root.mkdir(parents=True, exist_ok=True)
        self.reference_roots = {}

    def path(self, key):
        if key.startswith('references/'):
            _, root_id, relative = key.split('/', 2)
            root = self.reference_roots[root_id]
            path = (root / relative).resolve()
            if not path.is_relative_to(root.resolve()) or path == root.resolve():
                raise ValueError('Invalid reference key')
            return path
        path = (self.root / key).resolve()
        if not path.is_relative_to(self.root) or path == self.root:
            raise ValueError('Invalid storage key')
        return path

    def put(self, source, key):
        target = self.path(key)
        target.parent.mkdir(parents=True, exist_ok=True)
        # Keep staging until metadata commits. Atomic replacement avoids partial files.
        temp = target.with_suffix('.pending')
        import shutil
        shutil.copyfile(source, temp)
        temp.replace(target)
        return target

    def delete(self, key):
        self.path(key).unlink(missing_ok=True)


def checksum(path):
    with open(path, 'rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()
