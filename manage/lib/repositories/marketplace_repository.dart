import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace/marketplace.dart';
import '../config/supabase_config.dart';

/// Repository for marketplace operations
class MarketplaceRepository {
  final SupabaseClient _client;

  // Table names
  static const String _listingsTable = 'marketplace_listings';
  static const String _listingsView = 'marketplace_listings_view';
  static const String _sellerProfilesTable = 'marketplace_seller_profiles';
  static const String _inquiriesTable = 'marketplace_inquiries';
  static const String _conversationsTable = 'marketplace_conversations';
  static const String _messagesTable = 'marketplace_messages';
  static const String _favoritesTable = 'marketplace_favorites';
  static const String _transactionsTable = 'marketplace_transactions';
  static const String _reviewsTable = 'marketplace_reviews';
  static const String _auctionsTable = 'marketplace_auctions';
  static const String _bidsTable = 'marketplace_bids';
  static const String _savedSearchesTable = 'marketplace_saved_searches';
  static const String _reportsTable = 'marketplace_reports';
  static const String _blockedUsersTable = 'marketplace_blocked_users';

  MarketplaceRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Get current user's seller profile
  Future<SellerProfile?> getMySellerProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(_sellerProfilesTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return SellerProfile.fromJson(response);
  }

  /// Get seller profile by ID
  Future<SellerProfile?> getSellerProfile(String id) async {
    final response = await _client
        .from(_sellerProfilesTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return SellerProfile.fromJson(response);
  }

  /// Create seller profile
  Future<SellerProfile> createSellerProfile({
    required String displayName,
    required String region,
    String? bio,
    String? farmName,
    String? farmDescription,
    int? yearsExperience,
    String? phoneNumber,
    String? whatsappNumber,
    double? latitude,
    double? longitude,
    String? district,
    String? village,
    String? address,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': userId,
      'display_name': displayName,
      'region': region,
      'bio': bio,
      'farm_name': farmName,
      'farm_description': farmDescription,
      'years_experience': yearsExperience,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'district': district,
      'village': village,
      'address': address,
    };

    // Add location if provided
    if (latitude != null && longitude != null) {
      data['location'] = 'POINT($longitude $latitude)';
    }

    final response = await _client
        .from(_sellerProfilesTable)
        .insert(data)
        .select()
        .single();

    return SellerProfile.fromJson(response);
  }

  /// Update seller profile
  Future<SellerProfile> updateSellerProfile(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (updates.containsKey('latitude') && updates.containsKey('longitude')) {
      final lat = updates.remove('latitude');
      final lng = updates.remove('longitude');
      if (lat != null && lng != null) {
        updates['location'] = 'POINT($lng $lat)';
      }
    }

    final response = await _client
        .from(_sellerProfilesTable)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return SellerProfile.fromJson(response);
  }

  /// Get active listings with filters
  Future<List<MarketplaceListing>> getListings({
    String? species,
    String? breed,
    String? region,
    double? minPrice,
    double? maxPrice,
    ListingType? listingType,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from(_listingsView).select();

    if (species != null) query = query.eq('species', species);
    if (breed != null) query = query.eq('breed', breed);
    if (region != null) query = query.eq('region', region);
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (listingType != null) query = query.eq('listing_type', listingType.name);

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceListing.fromJson(json))
        .toList();
  }

  /// Search listings by location (nearby)
  Future<List<MarketplaceListing>> searchListingsNearby({
    required double latitude,
    required double longitude,
    int radiusKm = 50,
    String? species,
    String? breed,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'search_listings_nearby',
      params: {
        'search_lat': latitude,
        'search_lng': longitude,
        'radius_km': radiusKm,
        'p_species': species,
        'p_breed': breed,
        'p_min_price': minPrice,
        'p_max_price': maxPrice,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (response as List).map((json) {
      return MarketplaceListing(
        id: json['id'],
        sellerId: '', // Not returned by RPC
        species: json['species'],
        breed: json['breed'],
        title: json['title'],
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] ?? 'UGX',
        region: json['region'],
        district: json['district'],
        photoUrls: json['photo_url'] != null ? [json['photo_url']] : [],
        createdAt: DateTime.now(), // Not returned
        updatedAt: DateTime.now(), // Not returned
        sellerName: json['seller_name'],
        sellerRating: (json['seller_rating'] as num?)?.toDouble(),
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
      );
    }).toList();
  }

  /// Full-text search listings
  Future<List<MarketplaceListing>> searchListings({
    required String query,
    String? region,
    int limit = 20,
    int offset = 0,
  }) async {
    var request = _client
        .from(_listingsView)
        .select()
        .textSearch(
          'title,description,species,breed',
          query,
          config: 'english',
        );

    if (region != null) request = request.eq('region', region);

    final response = await request
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceListing.fromJson(json))
        .toList();
  }

  /// Get single listing by ID
  Future<MarketplaceListing?> getListing(String id) async {
    final response = await _client
        .from(_listingsView)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MarketplaceListing.fromJson(response);
  }

  /// Get my listings (as seller)
  Future<List<MarketplaceListing>> getMyListings({
    ListingStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final profile = await getMySellerProfile();
    if (profile == null) return [];

    var query = _client
        .from(_listingsTable)
        .select()
        .eq('seller_id', profile.id);

    if (status != null) query = query.eq('status', status.name);

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceListing.fromJson(json))
        .toList();
  }

  /// Create a new listing
  Future<MarketplaceListing> createListing(MarketplaceListing listing) async {
    final data = listing.toInsertJson();

    final response = await _client
        .from(_listingsTable)
        .insert(data)
        .select()
        .single();

    return MarketplaceListing.fromJson(response);
  }

  /// Update listing
  Future<MarketplaceListing> updateListing(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (updates.containsKey('latitude') && updates.containsKey('longitude')) {
      final lat = updates.remove('latitude');
      final lng = updates.remove('longitude');
      if (lat != null && lng != null) {
        updates['location'] = 'POINT($lng $lat)';
      }
    }

    final response = await _client
        .from(_listingsTable)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return MarketplaceListing.fromJson(response);
  }

  /// Publish listing (set status to active)
  Future<MarketplaceListing> publishListing(
    String id, {
    DateTime? expiresAt,
  }) async {
    return updateListing(id, {
      'status': 'active',
      'published_at': DateTime.now().toIso8601String(),
      'expires_at':
          expiresAt?.toIso8601String() ??
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
  }

  /// Mark listing as sold
  Future<MarketplaceListing> markListingAsSold(String id) async {
    return updateListing(id, {
      'status': 'sold',
      'sold_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete listing
  Future<void> deleteListing(String id) async {
    await _client.from(_listingsTable).delete().eq('id', id);
  }

  /// Increment view count
  Future<void> incrementListingViews(String id) async {
    await _client.rpc('increment_listing_views', params: {'p_listing_id': id});
  }

  /// Get market price stats
  Future<Map<String, dynamic>?> getMarketPriceStats({
    required String species,
    String? breed,
    String? region,
  }) async {
    final response = await _client.rpc(
      'get_market_price_stats',
      params: {'p_species': species, 'p_breed': breed, 'p_region': region},
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  /// Get user's favorites
  Future<List<MarketplaceFavorite>> getMyFavorites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(_favoritesTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MarketplaceFavorite.fromJson(json))
        .toList();
  }

  /// Add to favorites
  Future<MarketplaceFavorite> addToFavorites(
    String listingId, {
    double? priceAtSave,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from(_favoritesTable)
        .insert({
          'user_id': userId,
          'listing_id': listingId,
          'price_at_save': priceAtSave,
        })
        .select()
        .single();

    return MarketplaceFavorite.fromJson(response);
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String listingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from(_favoritesTable)
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }

  /// Check if listing is favorited
  Future<bool> isFavorited(String listingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from(_favoritesTable)
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', listingId)
        .maybeSingle();

    return response != null;
  }

  /// Send inquiry
  Future<MarketplaceInquiry> sendInquiry({
    required String listingId,
    required String message,
    double? offeredPrice,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from(_inquiriesTable)
        .insert({
          'listing_id': listingId,
          'buyer_id': userId,
          'message': message,
          'offered_price': offeredPrice,
        })
        .select()
        .single();

    return MarketplaceInquiry.fromJson(response);
  }

  /// Get inquiries for my listings (as seller)
  Future<List<MarketplaceInquiry>> getInquiriesForMyListings({
    InquiryStatus? status,
  }) async {
    final profile = await getMySellerProfile();
    if (profile == null) return [];

    // Get my listing IDs
    final listingsResponse = await _client
        .from(_listingsTable)
        .select('id')
        .eq('seller_id', profile.id);

    final listingIds = (listingsResponse as List)
        .map((l) => l['id'] as String)
        .toList();

    if (listingIds.isEmpty) return [];

    var query = _client
        .from(_inquiriesTable)
        .select()
        .inFilter('listing_id', listingIds);

    if (status != null) query = query.eq('status', status.name);

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => MarketplaceInquiry.fromJson(json))
        .toList();
  }

  /// Get my inquiries (as buyer)
  Future<List<MarketplaceInquiry>> getMyInquiries() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(_inquiriesTable)
        .select()
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MarketplaceInquiry.fromJson(json))
        .toList();
  }

  /// Respond to inquiry (as seller)
  Future<MarketplaceInquiry> respondToInquiry(
    String inquiryId, {
    required String responseMessage,
    InquiryStatus status = InquiryStatus.responded,
  }) async {
    final response = await _client
        .from(_inquiriesTable)
        .update({
          'response_message': responseMessage,
          'status': status.name,
          'responded_at': DateTime.now().toIso8601String(),
          'contact_revealed': status == InquiryStatus.accepted,
        })
        .eq('id', inquiryId)
        .select()
        .single();

    return MarketplaceInquiry.fromJson(response);
  }

  /// Get or create conversation
  Future<MarketplaceConversation> getOrCreateConversation({
    required String listingId,
    String? inquiryId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if conversation exists
    final existing = await _client
        .from(_conversationsTable)
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', userId)
        .maybeSingle();

    if (existing != null) {
      return MarketplaceConversation.fromJson(existing);
    }

    // Get listing to find seller
    final listing = await getListing(listingId);
    if (listing == null) throw Exception('Listing not found');

    final sellerProfile = await getSellerProfile(listing.sellerId);
    if (sellerProfile == null) throw Exception('Seller not found');

    // Create new conversation
    final response = await _client
        .from(_conversationsTable)
        .insert({
          'listing_id': listingId,
          'inquiry_id': inquiryId,
          'buyer_id': userId,
          'seller_id': sellerProfile.userId,
        })
        .select()
        .single();

    return MarketplaceConversation.fromJson(response);
  }

  /// Get my conversations
  Future<List<MarketplaceConversation>> getMyConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('marketplace_conversations_view')
        .select()
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false);

    return (response as List)
        .map((json) => MarketplaceConversation.fromJson(json))
        .toList();
  }

  /// Get messages for conversation
  Future<List<MarketplaceMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from(_messagesTable)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceMessage.fromJson(json))
        .toList();
  }

  /// Send message
  Future<MarketplaceMessage> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    double? offeredPrice,
    List<String>? attachmentUrls,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from(_messagesTable)
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
          'message_type': messageType.name,
          'offered_price': offeredPrice,
          'offer_status': offeredPrice != null ? 'pending' : null,
          'attachment_urls': attachmentUrls,
        })
        .select()
        .single();

    return MarketplaceMessage.fromJson(response);
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from(_messagesTable)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);

    // Reset unread count
    final conv = await _client
        .from(_conversationsTable)
        .select('buyer_id, seller_id')
        .eq('id', conversationId)
        .single();

    final isBuyer = conv['buyer_id'] == userId;
    await _client
        .from(_conversationsTable)
        .update({isBuyer ? 'buyer_unread_count' : 'seller_unread_count': 0})
        .eq('id', conversationId);
  }

  /// Watch messages (real-time)
  Stream<List<MarketplaceMessage>> watchMessages(String conversationId) {
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => MarketplaceMessage.fromJson(json)).toList(),
        );
  }

  /// Get reviews for a seller
  Future<List<MarketplaceReview>> getSellerReviews(
    String sellerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from(_reviewsTable)
        .select('''
          *,
          reviewer:reviewer_id(full_name, avatar_url)
        ''')
        .eq('seller_id', sellerId)
        .eq('is_visible', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) {
      // Flatten reviewer data
      final reviewer = json['reviewer'] as Map<String, dynamic>?;
      return MarketplaceReview.fromJson({
        ...json,
        'reviewer_name': reviewer?['full_name'],
        'reviewer_photo': reviewer?['avatar_url'],
      });
    }).toList();
  }

  /// Get review for a specific transaction
  Future<MarketplaceReview?> getTransactionReview(String transactionId) async {
    final response = await _client
        .from(_reviewsTable)
        .select()
        .eq('transaction_id', transactionId)
        .maybeSingle();

    if (response == null) return null;
    return MarketplaceReview.fromJson(response);
  }

  /// Create a review
  Future<MarketplaceReview> createReview(MarketplaceReview review) async {
    final response = await _client
        .from(_reviewsTable)
        .insert(review.toJson())
        .select()
        .single();

    return MarketplaceReview.fromJson(response);
  }

  /// Respond to a review (as seller)
  Future<MarketplaceReview> respondToReview(
    String reviewId,
    String response,
  ) async {
    final result = await _client
        .from(_reviewsTable)
        .update({
          'seller_response': response,
          'seller_responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reviewId)
        .select()
        .single();

    return MarketplaceReview.fromJson(result);
  }

  /// Get seller's average rating
  Future<Map<String, double>> getSellerRatings(String sellerId) async {
    final response = await _client
        .from(_reviewsTable)
        .select(
          'rating, communication_rating, accuracy_rating, delivery_rating',
        )
        .eq('seller_id', sellerId)
        .eq('is_visible', true);

    final reviews = response as List;
    if (reviews.isEmpty) {
      return {
        'overall': 0,
        'communication': 0,
        'accuracy': 0,
        'delivery': 0,
        'count': 0,
      };
    }

    double avgRating = 0;
    double avgComm = 0;
    double avgAcc = 0;
    double avgDel = 0;
    int commCount = 0;
    int accCount = 0;
    int delCount = 0;

    for (final r in reviews) {
      avgRating += (r['rating'] as int);
      if (r['communication_rating'] != null) {
        avgComm += (r['communication_rating'] as int);
        commCount++;
      }
      if (r['accuracy_rating'] != null) {
        avgAcc += (r['accuracy_rating'] as int);
        accCount++;
      }
      if (r['delivery_rating'] != null) {
        avgDel += (r['delivery_rating'] as int);
        delCount++;
      }
    }

    return {
      'overall': avgRating / reviews.length,
      'communication': commCount > 0 ? avgComm / commCount : 0,
      'accuracy': accCount > 0 ? avgAcc / accCount : 0,
      'delivery': delCount > 0 ? avgDel / delCount : 0,
      'count': reviews.length.toDouble(),
    };
  }

  /// Get auction for listing
  Future<MarketplaceAuction?> getAuction(String listingId) async {
    final response = await _client
        .from(_auctionsTable)
        .select()
        .eq('listing_id', listingId)
        .maybeSingle();

    if (response == null) return null;
    return MarketplaceAuction.fromJson(response);
  }

  /// Get active auctions
  Future<List<MarketplaceAuction>> getActiveAuctions({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from(_auctionsTable)
        .select()
        .eq('is_active', true)
        .gt('end_time', DateTime.now().toIso8601String())
        .order('end_time')
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceAuction.fromJson(json))
        .toList();
  }

  /// Place bid
  Future<MarketplaceBid> placeBid({
    required String auctionId,
    required double amount,
    double? maxAutoBid,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from(_bidsTable)
        .insert({
          'auction_id': auctionId,
          'bidder_id': userId,
          'amount': amount,
          'max_auto_bid': maxAutoBid,
        })
        .select()
        .single();

    return MarketplaceBid.fromJson(response);
  }

  /// Get bids for auction
  Future<List<MarketplaceBid>> getAuctionBids(
    String auctionId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from(_bidsTable)
        .select()
        .eq('auction_id', auctionId)
        .order('amount', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => MarketplaceBid.fromJson(json))
        .toList();
  }

  /// Report listing/user
  Future<void> createReport(MarketplaceReport report) async {
    await _client.from(_reportsTable).insert(report.toJson());
  }

  /// Block user
  Future<void> blockUser(String blockedUserId, {String? reason}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from(_blockedUsersTable).insert({
      'user_id': userId,
      'blocked_user_id': blockedUserId,
      'reason': reason,
    });
  }

  /// Unblock user
  Future<void> unblockUser(String blockedUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from(_blockedUsersTable)
        .delete()
        .eq('user_id', userId)
        .eq('blocked_user_id', blockedUserId);
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String otherUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from(_blockedUsersTable)
        .select('id')
        .or('user_id.eq.$userId,blocked_user_id.eq.$userId')
        .or('user_id.eq.$otherUserId,blocked_user_id.eq.$otherUserId')
        .maybeSingle();

    return response != null;
  }

  /// Get saved searches
  Future<List<MarketplaceSavedSearch>> getSavedSearches() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(_savedSearchesTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MarketplaceSavedSearch.fromJson(json))
        .toList();
  }

  /// Create saved search
  Future<MarketplaceSavedSearch> createSavedSearch(
    MarketplaceSavedSearch search,
  ) async {
    final response = await _client
        .from(_savedSearchesTable)
        .insert(search.toJson())
        .select()
        .single();

    return MarketplaceSavedSearch.fromJson(response);
  }

  /// Delete saved search
  Future<void> deleteSavedSearch(String id) async {
    await _client.from(_savedSearchesTable).delete().eq('id', id);
  }

  /// Get transaction by ID
  Future<MarketplaceTransaction?> getTransaction(String id) async {
    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MarketplaceTransaction.fromJson(response);
  }

  /// Get transactions for current user (as buyer or seller)
  Future<List<MarketplaceTransaction>> getMyTransactions({
    TransactionStatus? status,
    bool asBuyer = true,
    bool asSeller = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from(_transactionsTable).select();

    // Filter by role
    if (asBuyer && asSeller) {
      query = query.or('buyer_id.eq.$userId,seller_id.eq.$userId');
    } else if (asBuyer) {
      query = query.eq('buyer_id', userId);
    } else if (asSeller) {
      query = query.eq('seller_id', userId);
    }

    // Filter by status
    if (status != null) {
      query = query.eq('status', status.name);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => MarketplaceTransaction.fromJson(json))
        .toList();
  }

  /// Create a transaction
  Future<MarketplaceTransaction> createTransaction(
    MarketplaceTransaction transaction,
  ) async {
    final response = await _client
        .from(_transactionsTable)
        .insert(transaction.toJson())
        .select()
        .single();

    return MarketplaceTransaction.fromJson(response);
  }

  /// Update transaction status
  Future<MarketplaceTransaction> updateTransactionStatus(
    String id,
    TransactionStatus status, {
    String? disputeReason,
  }) async {
    final data = <String, dynamic>{'status': status.name};

    if (status == TransactionStatus.disputed && disputeReason != null) {
      data['dispute_reason'] = disputeReason;
      data['dispute_opened_at'] = DateTime.now().toIso8601String();
    }

    if (status == TransactionStatus.completed) {
      data['completed_at'] = DateTime.now().toIso8601String();
    }

    if (status == TransactionStatus.cancelled) {
      data['cancelled_at'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from(_transactionsTable)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return MarketplaceTransaction.fromJson(response);
  }

  /// Confirm transaction (buyer or seller)
  Future<MarketplaceTransaction> confirmTransaction(
    String id, {
    required bool asBuyer,
  }) async {
    final field = asBuyer ? 'buyer_confirmed' : 'seller_confirmed';

    final response = await _client
        .from(_transactionsTable)
        .update({field: true})
        .eq('id', id)
        .select()
        .single();

    return MarketplaceTransaction.fromJson(response);
  }

  /// Record payment for transaction
  Future<MarketplaceTransaction> recordPayment(
    String id, {
    required double amount,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    // Get current transaction
    final current = await getTransaction(id);
    if (current == null) throw Exception('Transaction not found');

    final newAmountPaid = current.amountPaid + amount;
    final paymentStatus = newAmountPaid >= current.totalAmount
        ? 'paid'
        : 'partial';

    final response = await _client
        .from(_transactionsTable)
        .update({
          'amount_paid': newAmountPaid,
          'payment_method': paymentMethod,
          'payment_reference': paymentReference,
          'payment_status': paymentStatus,
        })
        .eq('id', id)
        .select()
        .single();

    return MarketplaceTransaction.fromJson(response);
  }
}
