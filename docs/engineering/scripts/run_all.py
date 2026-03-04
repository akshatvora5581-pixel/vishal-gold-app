"""
run_all.py — Master runner: generates all 11 Vishal Gold client delivery DOCX documents.
"""
import subprocess, sys, os

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))

scripts = [
    "01_project_completion_report.py",
    "02_user_manual.py",
    "03_admin_manual.py",
    "04_credentials_handover.py",
    "05_qa_signoff_report.py",
    "06_security_disclosure.py",
    "07_deployment_guide.py",
    "08_data_privacy_policy.py",
    "09_maintenance_sla.py",
    "10_known_issues_log.py",
    "11_play_store_checklist.py",
    "12_vapt_report.py",
    "13_qa_report.py",
    "14_developer_guide.py",
    "15_qa_fixes.py",
    "16_qa_test_cases.py",
    "17_troubleshooting_guide.py",
]

print("=" * 60)
print("  Vishal Gold — Client Delivery Document Generator")
print("=" * 60)
errors = []
for script in scripts:
    path = os.path.join(SCRIPTS_DIR, script)
    print(f"\n▶ Running: {script}")
    result = subprocess.run([sys.executable, path], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ✗ ERROR:\n{result.stderr}")
        errors.append(script)
    else:
        print(result.stdout.strip())

print("\n" + "=" * 60)
if errors:
    print(f"  ✗ {len(errors)} script(s) failed: {errors}")
else:
    print(f"  ✓ All 15 documents generated successfully.")
    out = os.path.join(SCRIPTS_DIR, "..", "client_delivery")
    print(f"  📁 Output folder: {os.path.abspath(out)}")
print("=" * 60)
