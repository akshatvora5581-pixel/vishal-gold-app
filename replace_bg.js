// Script to replace white background of logo with dark #121212
const sharp = require('sharp');
const path = require('path');

const inputPath = path.join(__dirname, 'assets', 'logo.png');
const outputPath = path.join(__dirname, 'assets', 'logo_dark.png');

async function replaceBackground() {
    // Get image metadata first
    const meta = await sharp(inputPath).metadata();
    console.log(`Image size: ${meta.width}x${meta.height}, format: ${meta.format}`);

    // Step 1: Get the raw pixel data
    const { data, info } = await sharp(inputPath)
        .ensureAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true });

    const width = info.width;
    const height = info.height;
    const channels = info.channels; // 4 (RGBA)

    // Step 2: Create the dark background color (0x12, 0x12, 0x12)
    const bgR = 0x12, bgG = 0x12, bgB = 0x12;

    // Step 3: Replace white/near-white pixels with dark bg
    // White = pixels where R, G, B are all >= 240 (threshold for near-white)
    for (let i = 0; i < data.length; i += channels) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];
        const a = data[i + 3];

        // Check if pixel is white or near-white  
        if (r >= 240 && g >= 240 && b >= 240 && a > 200) {
            data[i] = bgR;
            data[i + 1] = bgG;
            data[i + 2] = bgB;
            data[i + 3] = 255;
        }
    }

    // Step 4: Save the output
    await sharp(data, {
        raw: {
            width: width,
            height: height,
            channels: channels,
        }
    })
        .png({ quality: 100, compressionLevel: 0 })
        .toFile(outputPath);

    console.log(`✅ Done! Saved to: ${outputPath}`);
}

replaceBackground().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});
