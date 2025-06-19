#!/usr/bin/env python3
"""
App Icon Generator for Flutter
Generates all required app icon sizes for iOS and Android from the logo.svg file.

Requirements:
- pip install Pillow cairosvg

Usage:
python generate_app_icons.py
"""

import os
import sys
from PIL import Image
import cairosvg
from io import BytesIO

# iOS App Icon sizes (points and actual pixels)
IOS_SIZES = [
    # iPhone
    {"size": 20, "scales": [2, 3], "idiom": "iphone"},  # 40x40, 60x60
    {"size": 29, "scales": [2, 3], "idiom": "iphone"},  # 58x58, 87x87
    {"size": 40, "scales": [2, 3], "idiom": "iphone"},  # 80x80, 120x120
    {"size": 60, "scales": [2, 3], "idiom": "iphone"},  # 120x120, 180x180
    
    # iPad
    {"size": 20, "scales": [1, 2], "idiom": "ipad"},   # 20x20, 40x40
    {"size": 29, "scales": [1, 2], "idiom": "ipad"},   # 29x29, 58x58
    {"size": 40, "scales": [1, 2], "idiom": "ipad"},   # 40x40, 80x80
    {"size": 76, "scales": [1, 2], "idiom": "ipad"},   # 76x76, 152x152
    {"size": 83.5, "scales": [2], "idiom": "ipad"},    # 167x167
    
    # App Store
    {"size": 1024, "scales": [1], "idiom": "ios-marketing"},  # 1024x1024
]

# Android mipmap sizes (density-independent pixels)
ANDROID_SIZES = [
    {"density": "mdpi", "size": 48},     # 48x48
    {"density": "hdpi", "size": 72},     # 72x72
    {"density": "xhdpi", "size": 96},    # 96x96
    {"density": "xxhdpi", "size": 144},  # 144x144
    {"density": "xxxhdpi", "size": 192}, # 192x192
]

def ensure_directory(path):
    """Create directory if it doesn't exist."""
    os.makedirs(path, exist_ok=True)

def svg_to_png(svg_path, output_path, size):
    """Convert SVG to PNG at specified size."""
    try:
        # Convert SVG to PNG using cairosvg
        png_data = cairosvg.svg2png(
            url=svg_path,
            output_width=size,
            output_height=size,
            background_color='white'  # Set white background
        )
        
        # Open with PIL to ensure proper format
        image = Image.open(BytesIO(png_data))
        
        # Convert to RGBA if needed and ensure proper format
        if image.mode != 'RGBA':
            image = image.convert('RGBA')
        
        # Create a white background
        background = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        
        # Paste the icon on the white background
        if image.mode == 'RGBA':
            background.paste(image, (0, 0), image)
        else:
            background.paste(image, (0, 0))
        
        # Convert to RGB for final output (removes alpha channel)
        final_image = Image.new('RGB', (size, size), (255, 255, 255))
        final_image.paste(background, (0, 0))
        
        # Save as PNG
        final_image.save(output_path, 'PNG', quality=100, optimize=True)
        print(f"Generated: {output_path} ({size}x{size})")
        
    except Exception as e:
        print(f"Error generating {output_path}: {e}")

def generate_ios_icons():
    """Generate iOS app icons."""
    print("Generating iOS app icons...")
    
    svg_path = "assets/images/logo.svg"
    ios_base_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    ensure_directory(ios_base_path)
    
    # Generate icons for each size and scale
    for icon_spec in IOS_SIZES:
        size = icon_spec["size"]
        for scale in icon_spec["scales"]:
            pixel_size = int(size * scale)
            
            if size == int(size):
                size_str = str(int(size))
            else:
                size_str = str(size)
            
            if scale == 1:
                filename = f"Icon-App-{size_str}x{size_str}@1x.png"
            else:
                filename = f"Icon-App-{size_str}x{size_str}@{int(scale)}x.png"
            
            output_path = os.path.join(ios_base_path, filename)
            svg_to_png(svg_path, output_path, pixel_size)

def generate_android_icons():
    """Generate Android app icons."""
    print("\nGenerating Android app icons...")
    
    svg_path = "assets/images/logo.svg"
    
    for android_spec in ANDROID_SIZES:
        density = android_spec["density"]
        size = android_spec["size"]
        
        android_path = f"android/app/src/main/res/mipmap-{density}"
        ensure_directory(android_path)
        
        output_path = os.path.join(android_path, "ic_launcher.png")
        svg_to_png(svg_path, output_path, size)

def create_contents_json():
    """Create Contents.json for iOS app icons."""
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    for icon_spec in IOS_SIZES:
        size = icon_spec["size"]
        idiom = icon_spec["idiom"]
        
        for scale in icon_spec["scales"]:
            if size == int(size):
                size_str = str(int(size))
            else:
                size_str = str(size)
            
            scale_str = f"{int(scale)}x" if scale != 1 else "1x"
            filename = f"Icon-App-{size_str}x{size_str}@{scale_str}.png"
            
            image_info = {
                "filename": filename,
                "idiom": idiom,
                "scale": scale_str,
                "size": f"{size_str}x{size_str}"
            }
            
            contents["images"].append(image_info)
    
    # Write Contents.json
    contents_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    import json
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"Created: {contents_path}")

def main():
    """Main function to generate all app icons."""
    print("🚀 Generating app icons from logo.svg...")
    print("=" * 50)
    
    # Check if logo.svg exists
    if not os.path.exists("assets/images/logo.svg"):
        print("❌ Error: assets/images/logo.svg not found!")
        sys.exit(1)
    
    try:
        # Generate iOS icons
        generate_ios_icons()
        
        # Create Contents.json for iOS
        create_contents_json()
        
        # Generate Android icons
        generate_android_icons()
        
        print("\n" + "=" * 50)
        print("✅ App icons generated successfully!")
        print("\n📱 iOS icons: ios/Runner/Assets.xcassets/AppIcon.appiconset/")
        print("🤖 Android icons: android/app/src/main/res/mipmap-*/")
        print("\n💡 Next steps:")
        print("1. Run 'flutter clean' to clear build cache")
        print("2. Run 'flutter pub get' to refresh dependencies")
        print("3. Build and test your app on both platforms")
        
    except ImportError as e:
        print(f"❌ Missing required packages: {e}")
        print("📦 Install required packages with:")
        print("   pip install Pillow cairosvg")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 