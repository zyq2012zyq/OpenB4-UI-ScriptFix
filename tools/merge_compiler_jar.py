import copy
import hashlib
import sys
import zipfile
from pathlib import Path


SOURCE, BUILD, TOOLS, OUTPUT = sys.argv[1:5]
REPLACE = {
    "xyz/daikirai/gui/ClickGui.class",
    "xyz/daikirai/gui/ClickGui$1.class",
    "xyz/daikirai/gui/CategoryComponent.class",
    "xyz/daikirai/gui/SliderComponent.class",
    "xyz/daikirai/module/GuiModule.class",
    "xyz/daikirai/script/ScriptManager.class",
    "assets/clickgui/modules.json",
}
BUNDLED_COMPILER = "b4-compiler/tools.jar"
NOTICE_FILES = {name: f"b4-compiler/{name}" for name in ("LICENSE", "ASSEMBLY_EXCEPTION", "THIRD_PARTY_README")}
JDK_ROOT = Path(TOOLS).parent.parent

with zipfile.ZipFile(SOURCE) as original, zipfile.ZipFile(BUILD) as build:
    original_names = set(original.namelist())
    assert REPLACE <= original_names and REPLACE <= set(build.namelist())
    assert BUNDLED_COMPILER not in original_names

    with zipfile.ZipFile(OUTPUT, "w") as merged:
        for info in original.infolist():
            data = build.read(info.filename) if info.filename in REPLACE else original.read(info.filename)
            merged.writestr(copy.copy(info), data)
        merged.write(TOOLS, BUNDLED_COMPILER, compress_type=zipfile.ZIP_STORED)
        for source_name, archive_name in NOTICE_FILES.items():
            merged.write(JDK_ROOT / source_name, archive_name)

    with zipfile.ZipFile(OUTPUT) as merged:
        assert merged.testzip() is None
        assert set(merged.namelist()) == original_names | {BUNDLED_COMPILER} | set(NOTICE_FILES.values())
        for name in original_names:
            expected = build.read(name) if name in REPLACE else original.read(name)
            assert hashlib.sha256(merged.read(name)).digest() == hashlib.sha256(expected).digest(), name
        with open(TOOLS, "rb") as source:
            assert hashlib.sha256(merged.read(BUNDLED_COMPILER)).digest() == hashlib.sha256(source.read()).digest()
        for source_name, archive_name in NOTICE_FILES.items():
            assert merged.read(archive_name) == (JDK_ROOT / source_name).read_bytes()
        preserved_script_classes = [name for name in original_names if name.startswith("xyz/daikirai/script/") and name != "xyz/daikirai/script/ScriptManager.class"]
        print(f"Replaced {len(REPLACE)} UI/compiler entries; preserved {len(preserved_script_classes)} other script entries byte-for-byte.")
