# FRIDAYRED — Product Specification Document

## 1. Product Overview

**FRIDAYRED** is a social wine ranking app where users build personal, taste-based wine rankings through pairwise comparisons — then leverage their friends' rankings to make smarter purchasing decisions at the store.

### Vision
Unlike traditional 5-star or 100-point wine ratings, this app captures *relative preference* — how much you liked a wine compared to every other wine you've tried in that grape variety.

### Growth Model
**Invite-only launch.** Each user receives **5 invite codes** upon joining. No limit on friends once on the platform.

### Launch Market
**New York City** — Check Availability feature limited to NYC retailers at launch.

---

## 2. Core Concepts

### 2.1 The Ranking Model
- Rankings are **per grape variety** (Malbec, Pinot Noir, etc.)
- Rankings are at the **WINE level**, not vintage
- Position-based (1 = best), ties allowed
- Percentile scores calculated from position

### 2.2 Wine Identity & Vintage
**Wine** = Producer + Wine Name + Primary Grape + Region  
**Vintage Tasting** = Specific experience (2019, 2020, etc.)

One wine, one ranking position, multiple vintage experiences.

### 2.3 Composite Scoring
- Percentile = `(Total - Rank) / (Total - 1) × 100`
- Weight = `√(total wines ranked)`
- Minimum 3 raters to display composite

---

## 3. App Structure

### 5-Tab Navigation

| Tab | Function |
|-----|----------|
| **Home** | Friend activity feed + wine search + invite card |
| **My List** | Personal rankings by grape variety |
| **Rate** | Wine search → vintage → comparison flow |
| **Map** | Nearby wine stores (Google Places) |
| **Profile** | Wine Passport with world map + stats |

---

## 4. Core Features

### 4.1 Home Tab
- Search bar for wines
- Persistent invite card (until 5 invites used)
- Friend activity feed (chronological)

### 4.2 My List Tab
- Horizontal grape variety switcher
- Ordered ranked list with position, wine name, best vintage
- Tie indicator for tied wines

### 4.3 Rate Tab (Rating Flow)
1. Search for wine (or add new)
2. Select vintage (or NV)
3. Optional photos + notes
4. Sentiment selection (Loved/Okay/Didn't love)
5. Adaptive comparison (1-6 swipes)
6. Wine placed in ranking

### 4.4 Map Tab
- Nearby wine/liquor stores via Google Places
- Store details, distance, website links

### 4.5 Profile Tab (Wine Passport)
- World map with wine region pins
- Stats: wines rated, regions, grapes, friends
- Share passport as image
- Invite codes remaining

---

## 5. Data Models

| Model | Key Fields |
|-------|------------|
| **Wine** | id, name, producer, primaryGrapeId, regionId |
| **GrapeVariety** | id, name, color (red/white/rosé) |
| **WineRegion** | id, name, country, lat/long |
| **Ranking** | id, userId, grapeId, entries[] |
| **RankEntry** | id, wineId, position, vintageTastings[] |
| **VintageTasting** | id, vintageYear, notes, photos, isBestVintage |
| **InviteCode** | id, code, ownerUserId, usedByUserId |
| **FeedEvent** | id, actorUserId, eventType, wineId, position |

---

## 6. Technical Stack

- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with ObservableObject
- **Ranking Engine**: AdaptiveRankingEngine (binary insertion)
- **Maps**: Apple MapKit
- **Future Backend**: Supabase (Postgres + Auth + Storage)

---

## 7. MVP Scope

### In Scope
- [x] Invite-only concept (codes generated)
- [x] Wine-level rankings by grape
- [x] Sentiment-based rating flow
- [x] Personal ranked lists
- [x] Friend activity feed
- [x] Wine Passport with stats
- [x] Nearby store map

### Post-MVP
- [ ] Full adaptive comparison flow (binary search)
- [ ] Wine Detail Page with composites
- [ ] Phone auth + username profiles
- [ ] Check Availability (NYC)
- [ ] Push notifications
- [ ] Camera wine recognition

---

## 8. Implementation Status

| Phase | Status |
|-------|--------|
| Data Models | ✅ Complete |
| AdaptiveRankingEngine | ✅ Complete |
| Home Tab (Feed + Search) | ✅ Complete |
| My List Tab | ✅ Complete |
| Rate Tab (Basic Flow) | ✅ Complete |
| Map Tab | ✅ Existing |
| Profile Tab (Passport) | ✅ Complete |
| Full Comparison Flow | 🔲 TODO |
| Supabase Integration | 🔲 TODO |

---

*Last Updated: February 2026*
