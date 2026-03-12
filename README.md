# 🏆 Vishal Gold - Jewelry Design & Ordering Platform

A premium Flutter application for jewelry wholesalers and retailers to browse, order, and upload gold jewelry designs. Built with Flutter and Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

---

## 📋 Table of Contents

1. [Features](#-features)
2. [Screenshots](#-screenshots)
3. [Tech Stack](#-tech-stack)
4. [Project Structure](#-project-structure)
5. [Prerequisites](#-prerequisites)
6. [Installation Guide](#-installation-guide)
7. [Supabase Configuration](#-supabase-configuration)
8. [Database Schema](#-database-schema)
9. [Running the App](#-running-the-app)
10. [Build for Production](#-build-for-production)
11. [Troubleshooting](#-troubleshooting)
12. [Contributing](#-contributing)

---

## ✨ Features

### For Retailers
- 📦 Browse jewelry collections (84 Ornaments, 92 Ornaments, 92 Chains)
- 🔍 View product details with high-quality images
- 🛒 Add products to cart and place orders
- 📋 Track order history and status
- ⏰ View recently viewed designs
- 🔔 Receive notifications about new stock

### For Wholesalers
- 🎨 All retailer features included
- 📤 Upload new jewelry designs for admin approval
- 🏢 Manage company profile
- 📊 Track uploaded designs status

### General Features
- 🔐 Secure authentication with email/password
- 👥 Role-based access control (Retailer/Wholesaler)
- ⚡ Real-time database with Supabase
- 🎨 Beautiful, modern UI with Material Design 3
- 📱 Offline-capable image caching
- 🔄 Pull-to-refresh functionality

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.9.2+ |
| **Language** | Dart 3.0+ |
| **Backend** | Supabase (PostgreSQL + Auth + Storage) |
| **State Management** | Provider |
| **Authentication** | Supabase Auth |
| **Database** | PostgreSQL (via Supabase) |
| **Storage** | Supabase Storage |

### Dependencies

```yaml
# State Management
provider: ^6.1.1

# Backend & Auth
supabase_flutter: ^2.0.0

# UI Components
cached_network_image: ^3.3.0
carousel_slider: ^5.1.1
flutter_svg: ^2.0.9
shimmer: ^3.0.0
smooth_page_indicator: ^2.0.1
google_fonts: ^8.0.0

# Image Handling
image_picker: ^1.0.4

# Utilities
intl: ^0.20.2
uuid: ^4.2.1
flutter_secure_storage: ^10.0.0
```

---

## 📁 Project Structure

```
vishal_gold/
├── 📂 lib/
│   ├── 📂 config/
│   │   └── app_config.dart          # ⚙️ App configuration & Supabase credentials
│   │
│   ├── 📂 constants/
│   │   ├── app_colors.dart          # 🎨 Color palette
│   │   ├── app_strings.dart         # 📝 Text constants
│   │   └── app_routes.dart          # 🛤️ Route definitions
│   │
│   ├── 📂 models/
│   │   ├── user.dart                # 👤 User model
│   │   ├── product.dart             # 💎 Product model
│   │   ├── cart_item.dart           # 🛒 Cart item model
│   │   ├── order.dart               # 📦 Order & OrderItem models
│   │   └── notification.dart        # 🔔 Notification model
│   │
│   ├── 📂 providers/
│   │   ├── auth_provider.dart       # 🔐 Authentication state
│   │   └── cart_provider.dart       # 🛒 Shopping cart state
│   │
│   ├── 📂 screens/
│   │   ├── splash_screen.dart       # 🚀 App entry point
│   │   ├── auth/                    # 🔑 Login & Signup
│   │   ├── company_details/         # 🏢 Wholesaler company info
│   │   ├── home/                    # 🏠 Main home screen
│   │   ├── product/                 # 💎 Product listing & details
│   │   ├── cart/                    # 🛒 Shopping cart
│   │   ├── order/                   # 📦 Order management
│   │   ├── profile/                 # 👤 User profile
│   │   ├── notifications/           # 🔔 Notifications
│   │   ├── recent/                  # ⏰ Recently viewed
│   │   └── upload/                  # 📤 Design uploads (wholesalers)
│   │
│   ├── 📂 services/
│   │   ├── supabase_service.dart    # 🌐 Backend API service
│   │   └── image_picker_service.dart # 📷 Image picking service
│   │
│   ├── 📂 utils/
│   │   └── validators.dart          # ✅ Form validation
│   │
│   ├── 📂 widgets/
│   │   ├── home/                    # 🏠 Home screen widgets
│   │   └── product/                 # 💎 Product widgets
│   │
│   └── main.dart                    # 🚀 App initialization
│
├── 📂 assets/
│   ├── images/                      # 🖼️ Image assets
│   └── icons/                       # 🎯 Icon assets
│
├── pubspec.yaml                     # 📦 Dependencies
└── README.md                        # 📖 This file
```

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### 1. Flutter SDK

```bash
# Check Flutter version (must be 3.9.2 or higher)
flutter --version

# If not installed, download from: https://flutter.dev/docs/get-started/install
```

### 2. Development Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.9.2+ | Framework |
| Dart SDK | 3.0+ | Language (bundled with Flutter) |
| Android Studio | Latest | Android development & emulator |
| VS Code | Latest | Code editor (optional) |
| Xcode | Latest | iOS development (Mac only) |
| Git | Latest | Version control |

### 3. Device Setup

**Android:**
- Enable Developer Options on your device
- Enable USB debugging
- OR use Android Emulator from Android Studio

**iOS (Mac only):**
- Open Simulator from Xcode
- OR connect physical iOS device

---

## 🚀 Installation Guide

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/akshatvora5581-pixel/vishal-gold-app.git

# Navigate to project directory
cd vishal-gold-app
```

### Step 2: Install Flutter Dependencies

```bash
# Get all dependencies
flutter pub get
```

### Step 3: Verify Flutter Setup

```bash
# Run Flutter doctor to check for any issues
flutter doctor -v
```

Make sure you see ✓ marks for:
- Flutter
- Android toolchain (for Android development)
- Xcode (for iOS development - Mac only)
- Chrome (for web development)
- Android Studio or VS Code

### Step 4: Configure Supabase (Already Configured)

The app is pre-configured with Supabase credentials. See [Supabase Configuration](#-supabase-configuration) if you need to use your own Supabase project.

### Step 5: Run the App

```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>
```

---

## 🔧 Supabase Configuration

### Current Configuration

The app is connected to an existing Supabase project:
- **Project URL:** `https://cnxxfqktzkzjfnsaqqej.supabase.co`
- **Region:** `ap-south-1` (Mumbai)

### Using Your Own Supabase Project

If you want to set up your own Supabase project, follow these steps:

#### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name:** `vishal-gold-app`
   - **Database Password:** (save this securely!)
   - **Region:** Choose closest to your users
5. Click "Create new project" and wait ~2 minutes

#### 2. Get Your API Keys

1. Go to **Project Settings** → **API**
2. Copy:
   - **Project URL:** `https://xxxx.supabase.co`
   - **anon/public key:** `eyJhbGci...` (this is safe to expose)

#### 3. Update App Configuration

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Replace with your Supabase credentials
  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // App Configuration (leave as is)
  static const String appName = 'Vishal Jewellers';
  static const int itemsPerPage = 20;
  static const int maxRecentViews = 30;
  static const int maxUploadImages = 10;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);
}
```

#### 4. Set Up Database Tables

Run the following SQL in Supabase SQL Editor (**SQL Editor** → **New query**):

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    user_type VARCHAR(20) CHECK (user_type IN ('retailer', 'wholesaler')),
    company_name VARCHAR(255),
    company_address TEXT,
    city VARCHAR(100),
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Products table
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_number VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(100),
    name VARCHAR(255),
    description TEXT,
    image_urls TEXT[],
    gross_weight DECIMAL(10,3),
    net_weight DECIMAL(10,3),
    purity INTEGER DEFAULT 92,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Cart items table
CREATE TABLE public.cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    added_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, product_id)
);

-- Orders table
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
    total_items INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Order items table
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INTEGER DEFAULT 1,
    tag_number VARCHAR(50),
    gross_weight DECIMAL(10,3),
    net_weight DECIMAL(10,3),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Wholesaler uploads table
CREATE TABLE public.wholesaler_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    image_urls TEXT[],
    description TEXT,
    category VARCHAR(50),
    item_name VARCHAR(255),
    quantity VARCHAR(50),
    size VARCHAR(50),
    weight_per_qty VARCHAR(50),
    total VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Admin notifications table
CREATE TABLE public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    upload_id UUID REFERENCES public.wholesaler_uploads(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Recent views table
CREATE TABLE public.recent_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, product_id)
);

-- Policies table
CREATE TABLE public.policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) UNIQUE CHECK (type IN ('about', 'privacy', 'terms', 'shipping', 'cancellation')),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 5. Set Up Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wholesaler_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recent_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Products policies (public read)
CREATE POLICY "Products are viewable by everyone" ON public.products
    FOR SELECT USING (true);

-- Cart policies
CREATE POLICY "Users can manage own cart" ON public.cart_items
    FOR ALL USING (auth.uid() = user_id);

-- Orders policies
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Order items policies
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert order items" ON public.order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Wholesaler uploads policies
CREATE POLICY "Users can manage own uploads" ON public.wholesaler_uploads
    FOR ALL USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Admin notifications (admin only - handled via service role)
CREATE POLICY "Allow insert admin notifications" ON public.admin_notifications
    FOR INSERT WITH CHECK (true);

-- Recent views policies
CREATE POLICY "Users can manage own recent views" ON public.recent_views
    FOR ALL USING (auth.uid() = user_id);

-- Policies table (public read)
CREATE POLICY "Policies are viewable by everyone" ON public.policies
    FOR SELECT USING (true);
```

#### 6. Set Up Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Create these buckets:
   - `uploads` - For design uploads (public)
   - `avatars` - For profile pictures (public)

3. Set bucket policies (click bucket → **Policies**):

```sql
-- For uploads bucket
CREATE POLICY "Anyone can view uploads" ON storage.objects
    FOR SELECT USING (bucket_id = 'uploads');
CREATE POLICY "Authenticated users can upload" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'uploads' AND auth.role() = 'authenticated');

-- For avatars bucket
CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update own avatar" ON storage.objects
    FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## 💾 Database Schema

### Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    users    │       │  products   │       │   orders    │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │◄──┐   │ id (PK)     │◄──┐   │ id (PK)     │
│ full_name   │   │   │ tag_number  │   │   │ user_id(FK) │──┐
│ email       │   │   │ category    │   │   │ order_number│  │
│ user_type   │   │   │ name        │   │   │ status      │  │
│ company_*   │   │   │ image_urls  │   │   │ total_items │  │
└─────────────┘   │   │ weights     │   │   └─────────────┘  │
                  │   └─────────────┘   │          │         │
                  │          │          │          ▼         │
┌─────────────┐   │          │          │   ┌─────────────┐  │
│ cart_items  │   │          │          │   │ order_items │  │
├─────────────┤   │          │          │   ├─────────────┤  │
│ id (PK)     │   │          │          │   │ id (PK)     │  │
│ user_id(FK) │───┘          │          └───│ product_id  │  │
│ product_id  │──────────────┤              │ order_id(FK)│◄─┘
│ quantity    │              │              │ quantity    │
└─────────────┘              │              └─────────────┘
                             │
┌─────────────┐              │          ┌─────────────────┐
│recent_views │              │          │wholesaler_uploads│
├─────────────┤              │          ├─────────────────┤
│ id (PK)     │              │          │ id (PK)         │
│ user_id(FK) │──────────────┤          │ user_id (FK)    │
│ product_id  │──────────────┘          │ image_urls      │
│ viewed_at   │                         │ status          │
└─────────────┘                         └─────────────────┘
```

### Tables Overview

| Table | Description | RLS |
|-------|-------------|-----|
| `users` | User profiles with role-based fields | ✅ |
| `products` | Jewelry items with images and specifications | ✅ |
| `cart_items` | Shopping cart entries | ✅ |
| `orders` | Customer orders | ✅ |
| `order_items` | Individual items in orders | ✅ |
| `wholesaler_uploads` | Wholesaler design submissions | ✅ |
| `notifications` | User notifications | ✅ |
| `admin_notifications` | Admin-specific alerts | ✅ |
| `recent_views` | Recently viewed products tracking | ✅ |
| `policies` | App policies (Privacy, Terms, etc.) | ✅ |

---

## 🏃 Running the App

### Development Mode

```bash
# Run in debug mode (hot reload enabled)
flutter run

# Run with verbose logging
flutter run -v

# Run on specific device
flutter run -d chrome      # Web
flutter run -d emulator-5554  # Android Emulator
flutter run -d iPhone-15   # iOS Simulator
```

### Useful Commands

```bash
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

---

## 📦 Build for Production

### Android

```bash
# Build APK (for direct installation)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)

```bash
# Build iOS app
flutter build ios --release

# Then open in Xcode for archive/distribution
open ios/Runner.xcworkspace
```

### Web

```bash
# Build for web
flutter build web --release

# Output: build/web/
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Flutter SDK Not Found

```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Verify
flutter --version
```

#### 2. Supabase Connection Error

- Check internet connection
- Verify Supabase URL and anon key in `app_config.dart`
- Check if Supabase project is active (not paused)

#### 3. Email Verification Not Sending

This is usually due to Supabase email rate limits:
- Wait 1 hour for rate limit to reset
- Check spam folder
- Consider using custom SMTP in Supabase settings

#### 4. Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### 5. Android Gradle Issues

```bash
# Navigate to android folder
cd android

# Clean Gradle
./gradlew clean

# Go back and run
cd ..
flutter run
```

#### 6. iOS Pod Issues (Mac)

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

---

## 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Olive Green | `#808000` | Primary color |
| Soft Gold | `#FFD700` | Secondary/Accent |
| Cream | `#FFFDD0` | Background |
| Warm Beige | `#F5E6D3` | Cards/Containers |
| Success Green | `#4CAF50` | Success states |
| Warning Yellow | `#FFC107` | Warning states |
| Error Red | `#F44336` | Error states |

---

## 👥 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Style Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Keep widgets small and reusable
- Document complex logic with comments
- Format code using `dart format`

---

## 📄 License

© 2026 Vishal Gold. All rights reserved.

This is proprietary software. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.

---

## 📞 Support

For issues, questions, or feature requests:

- 📧 Email: [Contact Development Team]
- 🐛 Issues: [GitHub Issues](https://github.com/akshatvora5581-pixel/vishal-gold-app/issues)

---

**Made with ❤️ using Flutter & Supabase**