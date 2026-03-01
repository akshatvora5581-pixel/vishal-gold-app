import os
import re

def migrate_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match withOpacity(alpha)
    # We want to change it to withValues(alpha: alpha)
    # Note: alpha is usually a float or a variable
    pattern = r'\.withOpacity\(\s*([\d\.\w]+)\s*\)'
    
    new_content = re.sub(pattern, r'.withValues(alpha: \1)', content)
    
    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    lib_dir = os.path.join(os.getcwd(), 'lib')
    modified_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                abspath = os.path.join(root, file)
                if migrate_file(abspath):
                    print(f"Migrated: {abspath}")
                    modified_count += 1
    
    print(f"Total files migrated: {modified_count}")

if __name__ == "__main__":
    main()
