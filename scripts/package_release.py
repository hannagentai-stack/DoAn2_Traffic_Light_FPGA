"""Package only current, reviewable project inputs and deliverables."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'releases/DoAn2_Traffic_Light_Anode_Chung.zip'

def build():
    files = [ROOT / name for name in ['README.md', '.gitignore', 'requirements.txt',
             'traffic_light_top.qpf', 'traffic_light_top.qsf', 'traffic_light_top.sdc']]
    for folder, patterns in {
        'rtl': ['*.vhd'], 'sim': ['*.vhd', '*.do', '*.bat', '*.ini'],
        'scripts': ['*.py'], 'bitstream': ['*.sof', '*.jic', '*.txt'],
    }.items():
        for pattern in patterns: files.extend((ROOT / folder).glob(pattern))
    for folder in ['reports', 'hardware', 'guides']:
        files.extend(p for p in (ROOT / 'docs' / folder).rglob('*') if p.is_file())
    files += [ROOT / 'docs/README.md', ROOT / 'scripts/README.md']
    files = sorted(set(files))
    OUTPUT.parent.mkdir(exist_ok=True)
    with ZipFile(OUTPUT, 'w', ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, 'DoAn2_Traffic_Light_Anode_Chung/' + path.relative_to(ROOT).as_posix())
    digest = hashlib.sha256(OUTPUT.read_bytes()).hexdigest()
    OUTPUT.with_suffix('.zip.sha256').write_text(f'{digest}  {OUTPUT.name}\n', encoding='ascii')
    print(f'Packaged {len(files)} files: {OUTPUT}')
if __name__ == '__main__': build()
