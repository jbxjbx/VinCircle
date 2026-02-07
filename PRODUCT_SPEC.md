# VinCircle - Product Specification Document

## 1. Product Overview

**VinCircle** is a social wine-tasting iOS app designed for wine enthusiasts to log, rate, and share their wine experiences with a close circle of friends (max 10 "Inner Circle" members).

### Vision
Create a private, intimate social experience around wine discovery—not a public feed, but a trusted circle of friends sharing genuine tasting notes and recommendations.

### Target Users
- Wine hobbyists who want to track their tastings
- Friend groups who enjoy wine together
- Users seeking local wine store recommendations

---

## 2. Core Features

### 2.1 Feed Tab
| Feature | Description | Status |
|---------|-------------|--------|
| Friend Posts | View wine posts from Inner Circle friends | ✅ Done |
| Photo Carousel | Swipe through multiple wine images | ✅ Done |
| Like & Comment | Engage with friends' posts | ✅ Done |
| Tier 1 Restriction | Only Inner Circle friends can comment | ✅ Done |

### 2.2 Discover Tab
| Feature | Description | Status |
|---------|-------------|--------|
| Map View | See nearby wine/liquor stores on a map | ✅ Done |
| Store Details | View store info, distance, open hours | ✅ Done |
| Friend Match | Highlight stores with wines your friends rated | ✅ Done |
| Get Directions | Open Apple Maps for navigation | ✅ Done |

### 2.3 My Cellar Tab (formerly "Post")
| Feature | Description | Status |
|---------|-------------|--------|
| Personal Feed | View your own posted tastings | ✅ Done |
| Delete Posts | Swipe to delete unwanted posts | ✅ Done |
| View Comments | See friend comments on your posts | ✅ Done |
| Add Tasting (FAB) | Start a new structured wine tasting entry | ✅ Done |

### 2.4 Circle Tab
| Feature | Description | Status |
|---------|-------------|--------|
| Friend List | View your Inner Circle (max 10 friends) | ✅ Done |
| Add Friend | Enter 6-digit code or scan QR | ✅ Done |
| View Leaderboard | See friend's top-rated wines (Elo ranking) | ✅ Done |
| View Friend Posts | Browse a specific friend's history | ✅ Done |

### 2.5 Profile Tab
| Feature | Description | Status |
|---------|-------------|--------|
| Stats Overview | Tastings count, avg score, countries, achievements | ✅ Done |
| Top 10 Wines | Personal leaderboard by Elo score | ✅ Done |
| Achievements | Badge system for milestones | ✅ Done |
| Settings | Account, notifications, privacy | ✅ Done |

---

## 3. Data Models

```
User
├── id: UUID
├── displayName: String
├── uniqueCode: String (6-digit invite code)
├── friendIds: [UUID] (max 10)
├── tastingCount: Int
└── achievements: [Achievement]

WinePost
├── id: UUID
├── authorId: UUID
├── wineName, producer, region, country, vintage
├── wineType: WineType (red, white, rosé, sparkling, dessert)
├── attributes: WineAttributes
├── subjectiveScore: Int (1-100)
├── imageURLs: [URL]
├── likeCount, commentCount: Int
└── createdAt: Date

Comment
├── id: UUID
├── postId: UUID
├── authorId: UUID
├── authorName: String
├── text: String
└── createdAt: Date

WineAttributes
├── acidity, sweetness, tannin, body, alcohol: Double (0-1)
├── flavorNotes: [FlavorNote]
├── finish: FinishLength?
└── oakInfluence: OakLevel?
```

---

## 4. User Flows

### 4.1 Adding a Wine Tasting
1. Tap "My Cellar" tab → Tap floating **+** button
2. **Step 1**: Search for wine (autocomplete from API)
3. **Step 2**: Select vintage year
4. **Step 3**: Rate attributes (sliders for acidity, body, etc.)
5. **Step 4**: Add photos (optional)
6. **Step 5**: Give overall score (1-100)
7. **Step 6**: Compare with previous wine (optional, for Elo)
8. Submit → Post appears in your feed and friends' Feed

### 4.2 Commenting on a Post
1. Tap comment bubble on any post (Feed or My Cellar)
2. If authorized (Inner Circle friend), type comment
3. Submit → Comment appears instantly

---

## 5. Design System

| Token | Value | Usage |
|-------|-------|-------|
| `wineRed` | #722F37 | Primary brand color, CTAs |
| `champagneGold` | #F7E7CE | Accent, scores, badges |
| `roseGold` | #B76E79 | Secondary accent |
| `deepBurgundy` | #4A0E0E | Dark backgrounds |

---

## 6. Future Roadmap

| Priority | Feature | Description |
|----------|---------|-------------|
| P0 | Supabase Backend | Replace MockDataService with real persistence |
| P0 | Auth | Apple Sign-In / Passkey authentication |
| P1 | Real Wine API | Integrate Wine-Searcher or Vivino API |
| P1 | Push Notifications | New comments, friend requests |
| P2 | Photo Upload | Cloud storage for wine images |
| P2 | Export Data | PDF/CSV of personal tasting history |
| P3 | Widgets | iOS home screen widget for recent tastings |

---

## 7. Technical Stack

- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with ObservableObject
- **Styling**: Custom Theme system with wine-inspired palette
- **Maps**: MapKit with MKLocalSearch
- **Future Backend**: Supabase (Postgres + Auth + Storage)

---

*Last Updated: February 2026*
