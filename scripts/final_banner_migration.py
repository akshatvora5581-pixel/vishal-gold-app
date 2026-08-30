import firebase_admin
from firebase_admin import credentials, firestore, storage
import os
import uuid

# --- CONFIGURATION ---
# 1. Download your service account key from Firebase Console -> Project Settings -> Service Accounts
# 2. Place it in this directory and rename it to 'service-account.json'
SERVICE_ACCOUNT_PATH = 'd:/CodeTech/VishalGoldApp/scripts/new-service-account.json'
BUCKET_NAME = 'vishal-jewelers.firebasestorage.app'

# Path to the generated images in your local brain directory
# Replace <id> with the actual conversation ID if needed
IMAGES_DIR = 'C:/Users/Rushabh Makim/.gemini/antigravity/brain/519db010-53da-4bc9-aa53-756928bfeec2/'

banners_data = [
    {"id": "banner_001", "name": "banner_luxury_gold_necklace", "title": "Eternal Luxury", "subtitle": "Discover our exclusive 22k gold collection.", "template": "theme1"},
    {"id": "banner_002", "name": "banner_diamond_ring_elegant", "title": "Royal Diamonds", "subtitle": "Timeless rings for your special moments.", "template": "theme2"},
    {"id": "banner_003", "name": "banner_traditional_indian_bangles", "title": "Traditional Grace", "subtitle": "Handcrafted bangles for every tradition.", "template": "full_image"},
    {"id": "banner_004", "name": "banner_emerald_necklace_royal", "title": "Imperial Emeralds", "subtitle": "Majestic emeralds set in fine platinum.", "template": "theme1"},
    {"id": "banner_005", "name": "banner_gold_coins_investment", "title": "Golden Investment", "subtitle": "Secure your future with pure 24k gold.", "template": "theme2"},
    {"id": "banner_006", "name": "banner_bridal_set_maang_tikka_retry", "title": "The Bridal Masterpiece", "subtitle": "Heavy Kundan sets for your big day.", "template": "theme1"},
    {"id": "banner_007", "name": "banner_mens_gold_watch_bracelet", "title": "Bold & Refined", "subtitle": "Signature gold watches and bracelets for men.", "template": "full_image"},
    {"id": "banner_008", "name": "banner_pearl_earrings_classic", "title": "Classic Pearl Collection", "subtitle": "Timeless elegance in every drop.", "template": "blank"},
    {"id": "banner_009", "name": "banner_ruby_choker_festive", "title": "The Festive Glow", "subtitle": "Rubies that capture every celebration.", "template": "theme1"},
    {"id": "banner_010", "name": "banner_modern_gold_cuff_minimal", "title": "Geometric Gold", "subtitle": "Modern designs for the contemporary woman.", "template": "blank"},
]

def migrate():
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        print(f"Error: {SERVICE_ACCOUNT_PATH} not found. Please download it from Firebase Console.")
        return

    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred) # Don't pass bucket here

    db = firestore.client()
    
    # Try to find bucket
    from google.cloud import storage as gcs
    client = gcs.Client.from_service_account_json(SERVICE_ACCOUNT_PATH)
    buckets = list(client.list_buckets())
    if not buckets:
        print("Error: No buckets found in this project. Please enable Firebase Storage.")
        return
    
    # Use the first one or search for one
    bucket_name = buckets[0].name
    print(f"Detected bucket: {bucket_name}")
    bucket = storage.bucket(bucket_name)

    print(f"Starting migration to {bucket_name}...")

    for i, data in enumerate(banners_data):
        # find the actual file (with timestamp)
        filename = [f for f in os.listdir(IMAGES_DIR) if f.startswith(data['name']) and f.endswith('.png')]
        if not filename:
            print(f"Skipping {data['name']}, file not found.")
            continue
        
        local_path = os.path.join(IMAGES_DIR, filename[0])
        remote_path = f"banners/{filename[0]}"
        
        # 1. Upload to Storage
        blob = bucket.blob(remote_path)
        blob.upload_from_filename(local_path)
        blob.make_public()
        image_url = blob.public_url
        print(f"Uploaded: {image_url}")

        # 2. Save to Firestore
        banner_doc = {
            "title": data['title'],
            "subtitle": data['subtitle'],
            "image_url": image_url,
            "template_type": data['template'],
            "action_type": "none",
            "action_value": "",
            "is_active": True,
            "order": i + 1,
            "terms_and_conditions": "*T&C Applied",
            "created_at": firestore.SERVER_TIMESTAMP
        }
        
        db.collection("banners").document(data['id']).set(banner_doc)
        print(f"Saved Firestore doc: {data['id']}")

    print("Migration complete!")

if __name__ == "__main__":
    migrate()
