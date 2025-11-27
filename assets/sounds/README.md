# Sound Files for Tasbih Counter

This app requires 3 sound files to be placed in the `assets/sounds/` directory:

## Required Sound Files

1. **tap.mp3** - Soft tap sound (plays on every count)
2. **milestone.mp3** - Milestone chime (plays at 33, 66, etc.)
3. **complete.mp3** - Completion gong (plays when target is reached)

## Where to Find Free Sound Files

### Option 1: Freesound.org
Visit [freesound.org](https://freesound.org) and search for:
- "soft click" or "gentle tap" for tap.mp3
- "chime" or "bell" for milestone.mp3
- "gong" or "singing bowl" for complete.mp3

### Option 2: Zapsplat.com
Visit [zapsplat.com](https://zapsplat.com) (free with attribution)
- Search for "UI click" for tap sound
- Search for "notification chime" for milestone
- Search for "meditation gong" for completion

### Option 3: Create Silent Placeholders
If you want to test without sounds, create silent MP3 files:
1. Use any audio editor (Audacity is free)
2. Create 0.1 second silent tracks
3. Export as MP3
4. Name them tap.mp3, milestone.mp3, complete.mp3

### Option 4: Use Online Generators
- [Bfxr](https://www.bfxr.net/) - Generate simple sound effects
- [ChipTone](https://sfbgames.itch.io/chiptone) - Create retro-style sounds

## File Specifications

- **Format**: MP3
- **Duration**: 0.1-1.0 seconds (keep them short)
- **Size**: < 50KB each (for lightweight app)
- **Sample Rate**: 44.1kHz recommended

## Installation

1. Download or create your sound files
2. Place them in `assets/sounds/` directory:
   ```
   assets/
     sounds/
       tap.mp3
       milestone.mp3
       complete.mp3
   ```
3. Run `flutter pub get`
4. The app will automatically use these sounds

## Note

The app will work without sound files - it will simply skip playing sounds if the files are not found. The haptic feedback will still work.
