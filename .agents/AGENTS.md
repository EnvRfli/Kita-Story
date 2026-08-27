# Kita Story Agent Rules

Welcome to the Kita Story project! When working on this codebase, you MUST adhere to the following rules:

## 1. Architecture & State Management
- **Feature-First Clean Architecture**: Code is organized inside `lib/features/` by feature (e.g., `auth`, `books`). Each feature has `models`, `repositories`, `providers`, and `ui`.
- **State Management**: Use `Provider` (specifically `ChangeNotifierProvider` and `Consumer`). Avoid using `setState` for global data; use it only for ephemeral UI state (e.g., form inputs, bottom sheet selections).
- **Backend**: Supabase. Do NOT use Firebase. Always fetch the client via `SupabaseNetwork.client`.
- **Navigation**: Use `go_router` (`context.push`, `context.go`, `context.pop`). Do NOT use standard `Navigator`.

## 2. UI/UX & Aesthetics (Crucial)
- **Theme**: Pastel, soft, cute, and elegant. 
- **Colors**: Rely on `AppColors` defined in `lib/core/theme/app_colors.dart`.
  - Backgrounds: `Color(0xFFFFF6F8)` (Soft Pinkish White)
  - Primary Text/Accents: `Color(0xFF6B4454)` (Deep Maroon/Brown)
  - Highlight/Buttons: `Color(0xFF3B6B8A)` (Dark Pastel Blue)
- **Components**: 
  - Use `BottomSheet` (`showModalBottomSheet`) for complex data entry on detail screens (e.g., adding notes, characters, updating progress) instead of cluttering the main screen or navigating away.
  - Containers should have rounded corners (`BorderRadius.circular(24)` or `16`).
  - Use subtle drop shadows for elevated cards.

## 3. Database Operations
- **Atomic-like Operations**: When saving a complex entity (like a Book with Genres, Characters, and Notes), save the parent entity first to get the `UUID`, then loop and save the child entities.
- Ensure all rows include `added_by` referencing `Supabase.auth.currentUser.id`.

## 4. Workflows
- **Always check `spec.md`** before implementing new features.
- If asked to create a new module (e.g., "Food Recipes" or "Travel"), follow the exact same architecture as the `books` feature.
