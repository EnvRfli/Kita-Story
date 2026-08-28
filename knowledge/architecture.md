# Kita Story Architecture & State Management

## Overview
Kita Story is a modular Couple Lifestyle Super-App built with Flutter and Supabase. It adheres strictly to the **Feature-First Clean Architecture**.

## Directory Structure
```
lib/
├── core/
│   ├── network/         # Supabase client initialization (`supabase_client.dart`)
│   ├── router/          # Declarative routing with go_router (`app_router.dart`)
│   ├── theme/           # App colors and themes (`app_colors.dart`, `app_theme.dart`)
│   └── utils/           # Helpers and formatters (`date_formatter.dart`)
├── features/
│   ├── auth/            # Authentication & Gamification base module
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   ├── widgets/     # Auth-specific reusable widgets
│   │   └── ui/
│   ├── books/           # Book Tracker module
│   │   ├── models/      # Data entities mapping to Supabase
│   │   ├── providers/   # State management
│   │   ├── repositories/# Supabase DB interactions
│   │   ├── widgets/     # Reusable UI components & bottom sheets
│   │   └── ui/          # Flutter screens
│   └── home/            # Home dashboard module
│       ├── widgets/     # Home components & cards
│       └── ui/
```

## State Management (Provider)
- Uses **Provider** (`ChangeNotifierProvider`, `Consumer`).
- Providers act as a bridge between the UI and Repositories.
- **Golden Rule**: UI files (`_screen.dart`) should rarely make direct Supabase calls. They should rely on their respective Providers.
- Exception: For complex detail pages (like `BookDetailScreen`), local fetching via `FutureBuilder` or `initState` is preferred to avoid cluttering global state, but it still utilizes the `Repository` methods.

## Database Interaction
- **Backend**: Supabase.
- **Atomic-like Operations**: When saving a complex entity with relations (e.g., Book + Genres + Notes), save the parent entity first to get the `UUID`, then loop and save the child entities asynchronously.
- **RLS/Foreign Keys**: Always ensure data inserted has the `added_by` column mapping to `Supabase.auth.currentUser.id`.
