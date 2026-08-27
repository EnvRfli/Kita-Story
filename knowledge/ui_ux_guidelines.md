# Kita Story UI/UX Guidelines

## Aesthetic Core
- **Vibe**: Pastel, cute, elegant, interactive, slight glassmorphism.
- **Backgrounds**: Soft tint `Color(0xFFFFF6F8)` (Soft Pinkish White).
- **Cards/Containers**: White or semi-transparent with heavy rounded corners (`BorderRadius.circular(24)` or `16`).
- **Shadows**: Subtle, low opacity shadows (e.g., `Colors.black.withOpacity(0.05)` atau `0.1`).

## Color Palette (from `app_colors.dart`)
- `softPink`: `Color(0xFFFFD1DC)`
- `softBlue`: `Color(0xFFADD8E6)`
- `mintGreen`: `Color(0xFF98FB98)`
- `lavender`: `Color(0xFFE6E6FA)`
- Primary Text/Accents: `Color(0xFF6B4454)` (Deep Maroon/Brown)
- Highlight Action/Buttons: `Color(0xFF3B6B8A)` (Dark Pastel Blue)

## Component Guidelines
### Bottom Sheets
- **Rule**: Use `showModalBottomSheet` for complex or secondary data entries on detail screens (e.g., adding notes, updating characters, updating reading progress).
- Do not clutter the main screen or navigate away entirely just for a small form.
- Always apply: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.
- Handle keyboard overlap using: `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`.

### Lists & Layouts
- **Horizontal Lists**: Used for characters (circular avatars).
- **Masonry/Grid**: Used for Notes (interlocking cards with alternating pastel colors).
- **Inputs**: Minimalist form fields. Remove default underlines using `border: InputBorder.none` and wrap the `TextField` in a custom `Container` with white background and `borderRadius: BorderRadius.circular(12)`.
