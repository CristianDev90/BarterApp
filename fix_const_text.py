from pathlib import Path
for path in Path('lib/screens').rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    new = text.replace('const Text(', 'Text(')
    if new != text:
        path.write_text(new, encoding='utf-8')
        print(path)
