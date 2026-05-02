# Keyboard Shortcuts Guide
## DNTS Inventory Management System - Map Navigation

---

## 🎹 Quick Reference

### Essential Navigation
| Key | Action |
|-----|--------|
| **ESC** | Close Inspector / Return to Overview |
| **Space** | Fit All Labs in View |
| **+** or **=** | Zoom In |
| **-** | Zoom Out |

### Camera Movement
| Key | Action |
|-----|--------|
| **↑** | Pan Up |
| **↓** | Pan Down |
| **←** | Pan Left |
| **→** | Pan Right |

*Note: Arrow keys only work when inspector panel is closed*

### Lab Navigation
| Key | Action |
|-----|--------|
| **1** | Jump to Lab 1 |
| **2** | Jump to Lab 2 |
| **3** | Jump to Lab 3 |
| **4** | Jump to Lab 4 |
| **5** | Jump to Lab 5 |
| **6** | Jump to Lab 6 |
| **7** | Jump to Lab 7 |

### Desk Navigation
| Key | Action |
|-----|--------|
| **Tab** | Next Desk in Current Lab |
| **Shift+Tab** | Previous Desk in Current Lab |

*Note: Only works when a desk is already active*

### Help
| Key | Action |
|-----|--------|
| **?** | Show This Keyboard Shortcuts Dialog |

---

## 💡 Tips & Tricks

### Efficient Workflow
1. Press **Space** to see all labs
2. Press **1-7** to jump to a specific lab
3. Click a desk to inspect it
4. Press **Tab** to cycle through desks in that lab
5. Press **ESC** to return to overview

### Quick Zoom
- Press **+** multiple times for rapid zoom in
- Press **-** multiple times for rapid zoom out
- Press **Space** to reset to fit-all view

### Navigation Without Mouse
1. Press **1-7** to jump to a lab
2. Press **Tab** to select first desk (if inspector was open)
3. Press **Tab** repeatedly to cycle through all desks
4. Press **ESC** to close and return to overview

---

## 🔧 Header Buttons

### Keyboard Icon (⌨️)
- Click to open keyboard shortcuts help dialog
- Same as pressing **?** key

### Reset View Icon (🔄)
- Clears saved camera position and active desk
- Returns to default "Fit All Labs" view
- Use if map state becomes corrupted

### Zoom Out Map Icon (🔍)
- Fits all labs in view
- Same as pressing **Space** key

### Zoom In Icon (🔍+)
- Zooms in by 20%
- Same as pressing **+** key

### Refresh Icon (↻)
- Reloads asset data from database
- Does not affect camera position

---

## 🎯 Common Tasks

### "I want to see all labs"
- Press **Space**
- Or click the "Zoom Out Map" button

### "I want to inspect a specific lab"
- Press **1-7** for the lab number
- Camera will animate to that lab's center

### "I want to move between desks quickly"
- Click any desk to open inspector
- Press **Tab** to go to next desk
- Press **Shift+Tab** to go to previous desk

### "I want to close the inspector"
- Press **ESC**
- Or click the X button in inspector panel

### "I want to pan around the map"
- Make sure inspector is closed (press **ESC**)
- Use **Arrow Keys** to pan
- Or click and drag with mouse

### "The map is in a weird position"
- Click the **Reset View** button (restart icon)
- Or press **Space** to fit all labs

---

## 🚫 Limitations

### When Keyboard Shortcuts Don't Work
- **Text input fields**: Shortcuts disabled when typing
- **Inspector open**: Arrow keys disabled (pan locked)
- **Dialog open**: Shortcuts disabled in modal dialogs

### Desk Cycling Requirements
- Must have an active desk (inspector open)
- Only cycles within the current lab
- Wraps around (last desk → first desk)

---

## 💾 Automatic State Saving

Your camera position and active desk are automatically saved:

### What Gets Saved
- Camera zoom level
- Camera pan position
- Currently inspected desk (if any)

### When It Saves
- Automatically after 500ms of no changes
- When you inspect a desk
- When you close the inspector

### When It Restores
- On page refresh
- On browser restart
- On app reopen

### How to Clear Saved State
- Click the **Reset View** button (restart icon)
- This clears all saved positions and returns to default view

---

## 🎨 Visual Feedback

### Toast Notifications
When you use keyboard shortcuts, a small notification appears showing:
- Lab name (e.g., "Lab 3")
- Desk ID (e.g., "L5_D12")
- Action (e.g., "Zoom In", "Fit All Labs")

### Animation
- Lab jumps animate smoothly to center
- Desk cycling animates to next desk
- ESC animates back to overview

---

## ❓ FAQ

**Q: Why don't arrow keys work?**
A: Arrow keys are disabled when the inspector panel is open. Press ESC to close it first.

**Q: How do I know which lab I'm in?**
A: Look at the desk IDs in the inspector panel (e.g., "L3_D05" = Lab 3, Desk 5).

**Q: Can I customize keyboard shortcuts?**
A: Not currently. Shortcuts follow standard conventions.

**Q: What if I forget the shortcuts?**
A: Press **?** or click the keyboard icon in the header.

**Q: Does Tab work if no desk is active?**
A: No. You must click a desk first to activate it.

**Q: Can I use number pad for lab navigation?**
A: Yes, both number row and number pad work.

---

## 🐛 Troubleshooting

### "Shortcuts aren't working"
1. Make sure you're not typing in a text field
2. Close any open dialogs
3. Click on the map to ensure it has focus
4. Try refreshing the page

### "Map is stuck in a weird position"
1. Click the **Reset View** button
2. Or press **Space** to fit all labs
3. If still stuck, clear browser cache

### "Tab cycling skips desks"
- This is normal - it only cycles through desks in the current lab
- Desks are cycled in ID order (D01, D02, D03...)

### "Camera position not saving"
1. Check browser localStorage is enabled
2. Try clicking **Reset View** and navigating again
3. Check browser console for errors

---

## 📱 Mobile/Touch Support

Keyboard shortcuts are designed for desktop use. On mobile:
- Use touch gestures (pinch to zoom, drag to pan)
- Tap desks to inspect
- Use on-screen buttons in header

---

*For more information, see NAVIGATION_IMPLEMENTATION.md*
