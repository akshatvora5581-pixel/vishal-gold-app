import os
import zipfile

def create_source_zip(source_dir, output_path):
    print(f"Creating source code zip at: {output_path}")       
    
    # Directories to completely ignore to keep the zip small and clean
    ignore_dirs = {
        'build', 
        '.dart_tool', 
        '.idea', 
        '.vscode', 
        '.git', 
        '.gradle', 
        '__pycache__',
        'build_log.txt'
    }

    # Files to explicitly exclude
    ignore_files = {
        'vishal_jewelers_release.jks',
        'key.properties'
    }

    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            # Modify dirs in-place to skip ignored directories
            dirs[:] = [d for d in dirs if d not in ignore_dirs and not d.endswith('.build')]
            
            # Additional path-based exclusion for android/.gradle or ios/Pods
            rel_root = os.path.relpath(root, source_dir)
            if 'android\\.gradle' in rel_root or 'ios\\Pods' in rel_root or 'android/.gradle' in rel_root or 'ios/Pods' in rel_root:
                continue

            for file in files:
                if file in ignore_files:
                    continue
                if file.endswith('.zip'):
                    continue
                    
                file_path = os.path.join(root, file)
                # Ensure we don't try to zip the output file itself
                if os.path.abspath(file_path) == os.path.abspath(output_path):
                    continue
                
                # Add file to zip
                arcname = os.path.relpath(file_path, source_dir)
                zipf.write(file_path, arcname)
    
    # Get size
    if os.path.exists(output_path):
        size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"Done! Created {output_path} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    source = r"d:\CodeTech\VishalJewelersApp"
    # Output to the same place as the APK for convenience
    out_zip = r"d:\CodeTech\VishalJewelersApp\build\app\outputs\flutter-apk\VishalJewelers_SourceCode.zip"
    
    # Ensure dir exists (it should since APK was built)
    os.makedirs(os.path.dirname(out_zip), exist_ok=True)
    
    create_source_zip(source, out_zip)
