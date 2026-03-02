#!/usr/bin/env python3
"""
firestore_cleanup.py
Removes ALL test/dummy data from Firestore before client delivery.
Keeps: admin users, super admin accounts, and notification_color config.
Deletes: products, categories, subcategories, banners, orders,
         sample_orders, notifications, audit_logs, flash_sales,
         crm_segments (non-system), analytics_events, cart items.

Usage:
  pip install firebase-admin
  python firestore_cleanup.py --service-account path/to/service-account.json

After running this, use your dev seed script to restore dummy data for development.
"""
import argparse
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed.")
    print("Install it with: pip install firebase-admin")
    sys.exit(1)


# Collections to fully wipe (all documents deleted)
COLLECTIONS_TO_CLEAR = [
    "products",
    "categories",
    "subcategories",
    "banners",
    "orders",
    "sample_orders",
    "notifications",
    "flash_sales",
    "analytics_events",
    "audit_logs",
    "gold_rate",          # will be re-entered by admin
    "promotions",
    "design_uploads",
]

# Collections that are partially preserved
# (we delete test users but keep admin accounts)
PARTIAL_COLLECTIONS = {
    "users": {
        "rule": "delete_if",
        "field": "role",
        "values": ["CUSTOMER", "WHOLESALER"],   # safe to wipe test customers
        "keep_values": ["ADMIN", "SUPER_ADMIN"], # never touch admin accounts
    }
}

BATCH_LIMIT = 400  # Firestore max batch size is 500 — stay safe


def delete_collection(db, collection_name: str, dry_run: bool):
    """Delete all documents in a collection in batches."""
    col_ref = db.collection(collection_name)
    deleted = 0
    while True:
        docs = col_ref.limit(BATCH_LIMIT).stream()
        batch = db.batch()
        count = 0
        for doc in docs:
            if dry_run:
                print(f"  [DRY RUN] Would delete: {collection_name}/{doc.id}")
            else:
                batch.delete(doc.reference)
            count += 1
        if count == 0:
            break
        if not dry_run:
            batch.commit()
        deleted += count
        print(f"  Deleted {deleted} docs from '{collection_name}'...")
    return deleted


def delete_partial(db, collection_name: str, rule: dict, dry_run: bool):
    """Delete documents from a collection based on a field filter rule."""
    col_ref = db.collection(collection_name)
    field  = rule["field"]
    values = rule["values"]
    keep   = rule["keep_values"]

    deleted = 0
    for value in values:
        query = col_ref.where(field, "==", value)
        while True:
            docs = query.limit(BATCH_LIMIT).stream()
            batch = db.batch()
            count = 0
            for doc in docs:
                data = doc.to_dict()
                # Double-safety: never delete preserved roles
                if data.get(field) in keep:
                    print(f"  SKIPPED (protected): {collection_name}/{doc.id}")
                    continue
                if dry_run:
                    print(f"  [DRY RUN] Would delete: {collection_name}/{doc.id} [{field}={data.get(field)}]")
                else:
                    batch.delete(doc.reference)
                count += 1
            if count == 0:
                break
            if not dry_run:
                batch.commit()
            deleted += count
            print(f"  Deleted {deleted} {value} docs from '{collection_name}'...")
    return deleted


def main():
    parser = argparse.ArgumentParser(
        description="Clean Firestore dummy data before client delivery."
    )
    parser.add_argument(
        "--service-account",
        required=True,
        help="Path to your Firebase service account JSON file.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be deleted without actually deleting.",
    )
    args = parser.parse_args()

    # Initialize Firebase Admin
    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    mode = "DRY RUN" if args.dry_run else "LIVE"
    print(f"\n{'='*60}")
    print(f"  Vishal Gold — Firestore Cleanup ({mode})")
    print(f"{'='*60}")

    if not args.dry_run:
        print("\n⚠️  WARNING: This will PERMANENTLY delete data from Firestore.")
        confirm = input("Type 'YES' to continue: ").strip()
        if confirm != "YES":
            print("Aborted.")
            sys.exit(0)

    total_deleted = 0

    # Wipe full collections
    for col in COLLECTIONS_TO_CLEAR:
        print(f"\n→ Clearing collection: '{col}'")
        n = delete_collection(db, col, args.dry_run)
        total_deleted += n
        print(f"  ✓ {n} documents {'(would be) ' if args.dry_run else ''}deleted")

    # Wipe partial collections
    for col, rule in PARTIAL_COLLECTIONS.items():
        print(f"\n→ Partial clear: '{col}' (keeping {rule['keep_values']})")
        n = delete_partial(db, col, rule, args.dry_run)
        total_deleted += n
        print(f"  ✓ {n} documents {'(would be) ' if args.dry_run else ''}deleted")

    print(f"\n{'='*60}")
    print(f"  Total: {total_deleted} documents {'(would be) ' if args.dry_run else ''}removed")
    print(f"  Admin accounts and app credentials preserved ✓")
    print(f"{'='*60}\n")

    if not args.dry_run:
        print("✅ Firestore is now clean and ready for client handover.")
        print("   → You can now build the release APK.")
        print("   → Use your dev seed script to restore dummy data for development.")


if __name__ == "__main__":
    main()
