import os
import re
import glob

def clean_vhdl(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove all VHDL comments (from -- to end of line)
    # We must be careful not to remove -- inside a string, but in VHDL it's rare.
    # A simple regex for comments:
    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE)

    # 2. Remove report and assert statements.
    # They usually end with a semicolon. 
    # Match 'assert <anything>;' or 'report <anything>;'
    # Use re.DOTALL to match across newlines.
    # We will look for standalone assert and report statements.
    content = re.sub(r'\bassert\b[^;]*;', '', content, flags=re.IGNORECASE | re.DOTALL)
    content = re.sub(r'\breport\b[^;]*;', '', content, flags=re.IGNORECASE | re.DOTALL)

    # 3. Clean up multiple empty lines
    lines = content.split('\n')
    cleaned_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped != '':
            cleaned_lines.append(line.rstrip())
    
    # Reassemble with a single empty line between blocks if needed, but for simplicity let's just keep original spacing without huge gaps.
    final_content = '\n'.join(cleaned_lines)

    # Let's add back a little bit of spacing for readability
    final_content = final_content.replace('begin', '\nbegin\n')
    final_content = final_content.replace('architecture', '\narchitecture')
    final_content = final_content.replace('entity', '\nentity')
    final_content = final_content.replace('process', '\nprocess')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(final_content)

if __name__ == '__main__':
    vhd_files = glob.glob('*.vhd')
    for f in vhd_files:
        clean_vhdl(f)
        print(f"Cleaned {f}")
