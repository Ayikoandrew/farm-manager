# Livestock Marketplace Roadmap

## Overview
A peer-to-peer marketplace integrated into Farm Manager where farmers can buy, sell, and trade livestock directly with other farmers in their region.

---

## Phase 1: Foundation (MVP) - 4 weeks

### 1.1 Database Schema ✅ COMPLETED
- [x] `marketplace_listings` - Animal listings for sale
  - id, seller_id, animal_id, price, currency, negotiable
  - listing_type (sale, auction, trade)
  - status (draft, active, sold, expired, cancelled)
  - location (lat, lng, region, district) - **PostGIS enabled**
  - views_count, inquiries_count
  - expires_at, created_at, updated_at

- [x] `marketplace_categories` - Seeded with common livestock
  - species, breed, age_range, purpose (dairy, meat, breeding, pet)

- [x] `marketplace_inquiries`
  - listing_id, buyer_id, message, status
  - offered_price (for negotiations)

- [x] `marketplace_favorites`
  - user_id, listing_id (saved/watchlist)

- [x] `marketplace_seller_profiles` - With PostGIS location
- [x] `marketplace_conversations` & `marketplace_messages` - Chat system
- [x] `marketplace_transactions` - Sale records
- [x] `marketplace_reviews` - Seller reviews
- [x] `marketplace_auctions` & `marketplace_bids` - Auction system
- [x] `marketplace_reports` & `marketplace_blocked_users` - Safety
- [x] `marketplace_saved_searches` - Notification system

### 1.2 Flutter Models ✅ COMPLETED
- [x] `marketplace_enums.dart` - All enums
- [x] `seller_profile.dart` - Seller profile model
- [x] `marketplace_listing.dart` - Listing model
- [x] `marketplace_conversation.dart` - Conversation & message models
- [x] `marketplace_transaction.dart` - Transaction, review, favorite, report models
- [x] `marketplace_auction.dart` - Auction & bid models
- [x] `marketplace_repository.dart` - Full repository with Supabase integration

### 1.3 Core API Endpoints (FastAPI) - **USER WILL IMPLEMENT**
- [ ] `POST /api/v1/marketplace/listings` - Create listing
- [ ] `GET /api/v1/marketplace/listings` - Browse/search listings
- [ ] `GET /api/v1/marketplace/listings/{id}` - View listing details
- [ ] `PUT /api/v1/marketplace/listings/{id}` - Update listing
- [ ] `DELETE /api/v1/marketplace/listings/{id}` - Remove listing
- [ ] `POST /api/v1/marketplace/inquiries` - Send inquiry
- [ ] `GET /api/v1/marketplace/my-listings` - Seller's listings
- [ ] `GET /api/v1/marketplace/my-inquiries` - Buyer's inquiries

### 1.4 Flutter UI (Basic)
- [ ] Marketplace tab in bottom navigation
- [ ] Listing grid/list view with filters
- [ ] Create listing form (link to existing animals)
- [ ] Listing detail page
- [ ] My listings management screen
- [ ] Basic search by species, location, price range

---

## Phase 2: Discovery & Trust - 3 weeks

### 2.1 Enhanced Search & Filtering
- [x] Location-based search (nearby farmers) - **DB function created**
- [ ] Advanced filters (age, weight, health status, vaccinated)
- [ ] Sort by: price, date, distance, popularity
- [x] Saved searches with notifications - **DB table created**

### 2.2 Seller Profiles & Verification
- [x] `marketplace_seller_profiles` - **DB table created**
  - bio, farm_description, years_experience
  - verification_status (unverified, phone_verified, farm_verified)
  - response_rate, response_time
  
- [x] `marketplace_reviews` - **DB table & Flutter model completed**
  - transaction_id, reviewer_id, seller_id
  - rating (1-5), communication/accuracy/delivery ratings
  - review_text, verified_purchase flag
  - seller_response support

- [x] Seller rating display - **Repository method `getSellerRatings()` completed**
- [ ] "Verified Seller" badge system - **UI pending**

### 2.3 Media & Presentation
- [ ] Multiple photos per listing (up to 10)
- [ ] Video upload support (30 sec max)
- [ ] Photo gallery with zoom
- [ ] Health certificate uploads (PDF/image)

---

## Phase 3: Communication & Negotiation - 3 weeks

### 3.1 In-App Messaging
- [x] `marketplace_conversations` - **DB table & Flutter model completed**
  - listing_id, buyer_id, seller_id
  - last_message_at, unread_count

- [x] `marketplace_messages` - **DB table & Flutter model completed**
  - conversation_id, sender_id, content, type
  - attachments (images, location share)
  - read_at, created_at

- [x] Real-time chat (Supabase Realtime) - **Realtime enabled for messages**
- [ ] Push notifications for new messages - **UI pending**
- [ ] Message templates (quick replies) - **UI pending**

### 3.2 Price Negotiation
- [ ] Make offer feature
- [ ] Counter-offer flow
- [ ] Accept/reject with reason
- [ ] Price history on listing

### 3.3 Contact Options
- [ ] WhatsApp integration (click to chat)
- [ ] Phone call button (with privacy - reveal after inquiry)
- [ ] Schedule farm visit request

---

## Phase 4: Transactions & Safety - 4 weeks

### 4.1 Transaction Management
- [x] `marketplace_transactions` - **DB table & Flutter model completed**
  - listing_id, buyer_id, seller_id, conversation_id
  - agreed_price, currency, quantity, payment_method
  - status (pending, in_progress, completed, disputed, cancelled)
  - delivery_method (pickup, delivery), delivery_fee, delivery_date
  - buyer_confirmed, seller_confirmed, dispute tracking
  - completed_at, cancelled_at

- [x] Repository methods - **CRUD, status updates, payment recording**
- [ ] Transaction flow UI - **UI pending**
- [ ] Mark as sold / Complete transaction - **UI pending**
- [ ] Generate sale receipt (PDF) - **UI pending**

### 4.2 Payment Integration (Optional)
- [ ] Mobile money integration (MTN, Airtel)
- [ ] Escrow option for high-value animals
- [ ] Payment status tracking

### 4.3 Safety Features
- [ ] Report listing (fraud, misrepresentation)
- [ ] Block user functionality
- [ ] Suspicious activity detection
- [ ] Listing moderation queue

---

## Phase 5: Advanced Features - 4 weeks

### 5.1 Auctions
- [x] `marketplace_auctions` - **DB table & Flutter model completed**
  - listing_id, starting_price, reserve_price
  - current_bid, bid_count, current_bidder_id, winner_id
  - start_time, end_time
  - auto_extend (if bid in last 5 min)

- [x] `marketplace_bids` - **DB table & Flutter model completed**
  - auction_id, bidder_id, amount, max_auto_bid
  - is_winning, is_auto_bid, created_at

- [x] Realtime enabled for auctions & bids
- [ ] Live auction UI with countdown - **UI pending**
- [ ] Bid notifications - **UI pending**
- [ ] Proxy bidding (auto-bid up to max) - **UI pending**

### 5.2 Bulk Listings & Lots
- [ ] Sell multiple animals as a lot
- [ ] Bulk pricing (e.g., "10 goats for X")
- [ ] Mixed lot support

### 5.3 Wanted Ads
- [ ] "Looking to buy" posts
- [ ] Match buyers with sellers
- [ ] Notification when matching listing posted

---

## Phase 6: Analytics & Growth - 3 weeks

### 6.1 Seller Dashboard
- [ ] Listing performance metrics
- [ ] Views, inquiries, conversion rate
- [ ] Price comparison (market rates)
- [ ] Best time to list suggestions

### 6.2 Market Insights
- [ ] Average prices by species/breed/region
- [ ] Price trends over time
- [ ] Demand heatmap by location
- [ ] Seasonal patterns

### 6.3 Promotion Tools
- [ ] Featured listings (paid)
- [ ] Boost listing visibility
- [ ] Social sharing (WhatsApp, Facebook)

---

## Phase 7: AI Integration - 2 weeks

### 7.1 AI-Powered Features
- [ ] Smart pricing suggestions based on:
  - Animal attributes (age, weight, breed)
  - Market conditions
  - Historical sales data
  
- [ ] Auto-generate listing descriptions from animal data
- [ ] Image quality assessment
- [ ] Fraud detection (duplicate photos, suspicious patterns)

### 7.2 Assistant Integration
- [ ] "List Maria for sale" → Creates listing via GenUI
- [ ] "Show me goats for sale nearby" → Marketplace search
- [ ] "What's the market price for a 2-year-old Ankole cow?" → Market insights

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
├─────────────────────────────────────────────────────────────────┤
│  Marketplace     │  Messaging    │  Transactions  │  Profile    │
│  - Browse        │  - Chat       │  - Escrow      │  - Reviews  │
│  - Search        │  - Negotiate  │  - Receipts    │  - Verify   │
│  - Create        │  - Notify     │  - Dispute     │  - Stats    │
└────────┬────────────────┬───────────────┬──────────────┬────────┘
         │                │               │              │
         ▼                ▼               ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FastAPI Backend                             │
├─────────────────────────────────────────────────────────────────┤
│  /marketplace/*   │  /messages/*  │  /payments/*  │  /users/*   │
│  - CRUD listings  │  - Realtime   │  - Mobile $   │  - Verify   │
│  - Search/filter  │  - Push       │  - Escrow     │  - Reviews  │
│  - Recommendations│  - Templates  │  - Receipts   │  - Block    │
└────────┬────────────────┬───────────────┬──────────────┬────────┘
         │                │               │              │
         ▼                ▼               ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Supabase                                  │
├─────────────────────────────────────────────────────────────────┤
│  PostgreSQL       │  Realtime     │  Storage      │  Auth       │
│  - Listings       │  - Messages   │  - Photos     │  - Users    │
│  - Transactions   │  - Bids       │  - Videos     │  - Profiles │
│  - Reviews        │  - Prices     │  - Documents  │  - Verify   │
│  + PostGIS (geo)  │               │               │             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Models (Key Entities)

### Listing
```dart
class MarketplaceListing {
  String id;
  String sellerId;
  String? animalId;  // Link to existing animal (optional)
  
  // Animal details (can be from animal or manual entry)
  String species;
  String? breed;
  String? name;
  int? ageMonths;
  double? weightKg;
  String? gender;
  String healthStatus;
  
  // Listing details
  double price;
  String currency;  // UGX, KES, TZS, USD
  bool negotiable;
  ListingType type;  // sale, auction, trade
  ListingStatus status;
  
  // Location
  double? latitude;
  double? longitude;
  String region;
  String? district;
  
  // Media
  List<String> photoUrls;
  String? videoUrl;
  List<String> documentUrls;  // Health certs
  
  // Stats
  int viewsCount;
  int inquiriesCount;
  int favoritesCount;
  
  // Timestamps
  DateTime createdAt;
  DateTime? expiresAt;
}
```

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 1. Foundation | 4 weeks | Basic CRUD, listing UI, search |
| 2. Discovery & Trust | 3 weeks | Filters, seller profiles, reviews |
| 3. Communication | 3 weeks | Chat, negotiation, notifications |
| 4. Transactions | 4 weeks | Sale flow, payments, safety |
| 5. Advanced | 4 weeks | Auctions, bulk, wanted ads |
| 6. Analytics | 3 weeks | Dashboard, insights, promotions |
| 7. AI Integration | 2 weeks | Smart pricing, assistant |

**Total: ~23 weeks (6 months)**

---

## MVP Scope (Phase 1 Only)

For a quick launch, focus on:
1. ✅ Create listing (link to existing animal or manual entry)
2. ✅ Browse listings with basic filters
3. ✅ View listing details
4. ✅ Contact seller (WhatsApp/phone)
5. ✅ My listings management
6. ✅ Basic location display

**MVP Timeline: 4 weeks**

---

## Success Metrics

- **Listings**: # of active listings
- **Engagement**: Views per listing, inquiry rate
- **Conversion**: % of listings that sell
- **Retention**: Repeat sellers, repeat buyers
- **Trust**: Average seller rating, dispute rate
- **Revenue** (if monetized): Featured listings, transaction fees
