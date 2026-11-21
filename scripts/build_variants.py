#!/usr/bin/env python3
"""Two installs built from one canonical addon tree; no divergent core copies."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED, ZipInfo

ROOT=Path(__file__).resolve().parents[1]
BASE="KordRotation"
DEV="KordRotationDevTools"
FIXED=(2026,1,1,0,0,0)

def contents(root, addon):
    base=root/addon
    toc=base/(addon+".toc")
    if not toc.is_file():
        raise ValueError("Missing addon TOC: "+addon)
    lines=toc.read_text(encoding="utf-8-sig").splitlines()
    if addon==DEV:
        if not any(line.strip()=="## Dependencies: KordRotation" for line in lines):
            raise ValueError("DevTools must depend on canonical KordRotation")
        if not any(line.strip()=="## SavedVariables: KordRotationDevToolsDB" for line in lines):
            raise ValueError("DevTools must use separate SavedVariables")
    for raw in lines:
        line=raw.strip()
        if not line or line.startswith("#"):
            continue
        relative=line.replace("\\","/")
        if not relative.endswith(".lua") or relative.startswith("/") or any(
                piece in ("","..",".") for piece in relative.split("/")):
            raise ValueError("Unexpected TOC entry: "+line)
        if not (base/relative).is_file():
            raise ValueError("Missing TOC-loaded Lua: "+addon+"/"+relative)
    return sorted(p for p in base.rglob("*") if p.is_file() and not p.is_symlink())

def build(root, dest):
    ordinary=contents(root, BASE)
    diagnostic=contents(root, DEV)
    dest.mkdir(parents=True, exist_ok=True)
    common={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in ordinary}
    paths={}
    for variant, files in (("KordRotation-user",ordinary),("KordRotation-dev",ordinary+diagnostic)):
        archive=dest/(variant+".zip")
        with ZipFile(archive,"w",ZIP_DEFLATED,compresslevel=9) as z:
            for p in sorted(files):
                name=p.relative_to(root).as_posix()
                info=ZipInfo(name,FIXED)
                info.compress_type=ZIP_DEFLATED
                info.external_attr=0o644<<16
                z.writestr(info,p.read_bytes(),compress_type=ZIP_DEFLATED,compresslevel=9)
        paths[variant]=archive
    with ZipFile(paths["KordRotation-user"]) as user, ZipFile(paths["KordRotation-dev"]) as dev:
        assert set(user.namelist())==set(common)
        assert set(common).issubset(set(dev.namelist()))
        assert all(user.read(name)==dev.read(name) for name in common)
        assert not any(n.startswith(DEV+"/") for n in user.namelist())
        assert any(n.startswith(DEV+"/") for n in dev.namelist())
    report={"policy":"byte-identical KordRotation in both variants",
            "core_sha256":common,
            "core_files":len(common),"dev_files":len(diagnostic)}
    (dest/"build-manifest.json").write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    return report

if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=Path,default=ROOT)
    ap.add_argument("--out",type=Path,default=ROOT/"dist")
    args=ap.parse_args()
    print(json.dumps(build(args.source,args.out),ensure_ascii=False,sort_keys=True))
