# Testing Guide - Tasbih Counter App

## 🏃 Running the App

### Quick Start
```bash
# Run on connected device/emulator
flutter run

# Run on Chrome (fastest for UI testing)
flutter run -d chrome

# Run with hot reload enabled (default)
flutter run --hot
```

### Build Options
```bash
# Debug build (for testing)
flutter run --debug

# Profile build (for performance testing)
flutter run --profile

# Release build (for final testing)
flutter run --release
```

## ✅ Feature Testing Checklist

### 1. Counter Functionality
- [ ] **Tap anywhere** on screen - counter increments
- [ ] **Long press** counter area - reset dialog appears
- [ ] Counter bounces on tap (animation)
- [ ] Haptic feedback on every tap

### 2. Progress Ring
- [ ] Ring fills as counter increases
- [ ] Milestone markers appear at 33, 66, etc.
- [ ] Glow effect appears when near completion (80%+)
- [ ] Progress percentage badge shows correct value
- [ ] Smooth animations (300ms)

### 3. Confetti Celebration
- [ ] Count to 33 - confetti appears!
- [ ] Particles fall with physics
- [ ] Multiple colors
- [ ] Auto-disappears after 2 seconds
- [ ] Double vibration at milestones

### 4. Quick Zikr Switcher
- [ ] **Tap zikr name badge** - bottom sheet opens
- [ ] Shows all zikr with progress circles
- [ ] Active zikr highlighted
- [ ] Tap any zikr to switch
- [ ] Sheet closes smoothly

###  5. Statistics View
- [ ] **Tap bar chart icon** - stats appear
- [ ] Shows total count
- [ ] Shows completion percentage
- [ ] Shows active zikr count
- [ ] Displays top zikr list
- [ ] Colorful stat cards

### 6. Presets Management
- [ ] **Tap list icon** - presets screen opens
- [ ] Empty state shows icon and message
- [ ] **Tap +** button - add dialog opens
- [ ] **Fill form** and tap "Add" - zikr created
- [ ] **Long press** zikr card - edit dialog opens
- [ ] **Swipe left** - delete confirmation appears
- [ ] **Delete** - undo snackbar appears
- [ ] **Tap undo** - zikr restored
- [ ] Active zikr has "ACTIVE" badge
- [ ] Progress circles show correct progress
- [ ] **Tap edit button** - edit dialog opens
- [ ] **Tap info icon** - help dialog shows

### 7. Sound & Haptics
- [ ] **Tap sound toggle** - icon changes
- [ ] Tap sound plays (if enabled)
- [ ] Milestone chime at 33, 66 (if enabled)
- [ ] Completion gong at target (if enabled)
- [ ] Medium haptic on every tap
- [ ] Double vibration at milestones
- [ ] Triple vibration at completion

### 8. Visual Polish
- [ ] Gradient backgrounds
- [ ] Smooth transitions
- [ ] Filled tonal buttons
- [ ] Tooltips on icons
- [ ] Hint text at bottom
- [ ] Ayah text displays (if set)
- [ ] Dark/Light mode works

## 🧪 Testing Scenarios

### Scenario 1: First Time User
1. App opens with default "SubhanAllah" zikr
2. Tap screen 10 times - watch counter increase
3. See progress ring fill, percentage update
4. Long press - reset dialog appears
5. Confirm reset - counter goes to 0

### Scenario 2: Milestone Testing
1. Tap to 33 - confetti appears!
2. Double vibration, chime sound
3. Continue to 66 - another celebration
4. Reach target (33 for default) - completion gong

### Scenario 3: Managing Zikr
1. Tap list icon → Presets
2. See 3 default zikr
3. Tap + → Add dialog
4. Enter: Name="Test Zikr", Target=10
5. Tap Add → Snackbar confirmation
6. Long press card → Edit dialog
7. Change target to 20
8. Tap Update → Success message
9. Swipe left to delete
10. Tap Undo → Restored!

### Scenario 4: Quick Switching
1. On home screen, tap zikr name badge
2. Bottom sheet slides up
3. Tap "Alhamdulillah"
4. Sheet closes, screen updates
5. Counter shows Alhamdulillah's progress

### Scenario 5: Statistics
1. Count SubhanAllah to 10
2. Switch to Alhamdulillah, count to 5
3. Tap bar chart icon
4. See total: 15 counts
5. See completion rates
6. Check top zikr list

## 🐛 Things to Check

### Performance
- [ ] Animations run at 60fps
- [ ] No lag when tapping rapidly
- [ ] Quick switcher opens instantly
- [ ] No jank during confetti

### UI/UX
- [ ] All text readable in both themes
- [ ] Icons have tooltips
- [ ] Dialogs center properly
- [ ] Snackbars don't overlap content
- [ ] Safe area respected on notched devices

### Edge Cases
- [ ] What happens at count 999+? (works fine)
- [ ] Delete last zikr? (should keep at least 1)
- [ ] Very long zikr name? (truncates with ...)
- [ ] Target = 0? (progress shows 0%)
- [ ] Rapid tapping? (smooth, no missed taps)

## 📱 Platform-Specific Testing

### Android
```bash
flutter run -d android
```
- Test haptic feedback (works on most devices)
- Test back button (should close dialogs/sheets)
- Test notification shade (app pauses correctly)

### iOS
```bash
flutter run -d ios
```
- Test haptic feedback (strong on iPhone)
- Test swipe gestures
- Test dark/light mode switching

### Web
```bash
flutter run -d chrome
```
- No haptic feedback (expected)
- Sound works in browser
- All interactions smooth

## 🔧 Debugging

### Verbose Logging
```bash
flutter run -v
```

### Performance Overlay
```bash
flutter run --profile
# Then in app: tap performance overlay button
```

### Check for Errors
```bash
flutter analyze
flutter test
```

## 📊 Expected Results

✅ **Working:**
- Counter increments smoothly
- Confetti on milestones/completion
- Quick switcher functionality
- Edit/delete with undo
- Statistics tracking
- Sound toggle
- Persistent storage

⚠️ **Known Minor Issues:**
- 33 style warnings (withOpacity deprecated - cosmetic only)
- Sound files need to be added manually

## 🎯 Quick Test (2 minutes)

1. `flutter run -d chrome`
2. Tap screen 35 times
3. Watch confetti at 33!
4. Tap zikr name → switch
5. Tap bar chart → see stats
6. Tap list → add/edit zikr
7. Toggle sound
8. Long press reset

**If all works: ✅ Success!**

## 💡 Tips

- Use Chrome for fastest iteration
- Enable hot reload for quick changes
- Test on real device for haptics/sound
- Check both light and dark modes
- Test with different screen sizes

Happy testing! 🚀
