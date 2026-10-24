import copy
import hashlib
import sys
import zipfile
from pathlib import Path


SOURCE, PATCHED_CLASS, OUTPUT = sys.argv[1:4]
TARGET = "xyz/daikirai/script/ScriptDefaults$modules.class"
patched = Path(PATCHED_CLASS).read_bytes()

with zipfile.ZipFile(SOURCE) as original:
    assert TARGET in original.namelist()
    with zipfile.ZipFile(OUTPUT, "w") as result:
        for info in original.infolist():
            data = patched if info.filename == TARGET else original.read(info.filename)
            result.writestr(copy.copy(info), data)

    with zipfile.ZipFile(OUTPUT) as result:
        assert result.testzip() is None
        assert result.namelist() == original.namelist()
        for name in original.namelist():
            expected = patched if name == TARGET else original.read(name)
            assert hashlib.sha256(result.read(name)).digest() == hashlib.sha256(expected).digest(), name
        print("Patched slider API class; all other JAR entries preserved byte-for-byte.")
