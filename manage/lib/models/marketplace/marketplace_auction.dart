/// Auction model for listing_type = 'auction'
class MarketplaceAuction {
  final String id;
  final String listingId;
  final double startingPrice;
  final double? reservePrice;
  final double? buyNowPrice;
  final double bidIncrement;
  final double? currentBid;
  final String? currentBidderId;
  final int bidCount;
  final DateTime startTime;
  final DateTime endTime;
  final bool autoExtend;
  final int extensionMinutes;
  final bool reserveMet;
  final bool isActive;
  final String? winnerId;
  final double? winningBid;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceAuction({
    required this.id,
    required this.listingId,
    required this.startingPrice,
    this.reservePrice,
    this.buyNowPrice,
    this.bidIncrement = 10000,
    this.currentBid,
    this.currentBidderId,
    this.bidCount = 0,
    required this.startTime,
    required this.endTime,
    this.autoExtend = true,
    this.extensionMinutes = 5,
    this.reserveMet = false,
    this.isActive = false,
    this.winnerId,
    this.winningBid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceAuction.fromJson(Map<String, dynamic> json) {
    return MarketplaceAuction(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      startingPrice: (json['starting_price'] as num).toDouble(),
      reservePrice: (json['reserve_price'] as num?)?.toDouble(),
      buyNowPrice: (json['buy_now_price'] as num?)?.toDouble(),
      bidIncrement: (json['bid_increment'] as num?)?.toDouble() ?? 10000,
      currentBid: (json['current_bid'] as num?)?.toDouble(),
      currentBidderId: json['current_bidder_id'] as String?,
      bidCount: json['bid_count'] as int? ?? 0,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      autoExtend: json['auto_extend'] as bool? ?? true,
      extensionMinutes: json['extension_minutes'] as int? ?? 5,
      reserveMet: json['reserve_met'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      winnerId: json['winner_id'] as String?,
      winningBid: (json['winning_bid'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'starting_price': startingPrice,
      'reserve_price': reservePrice,
      'buy_now_price': buyNowPrice,
      'bid_increment': bidIncrement,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'auto_extend': autoExtend,
      'extension_minutes': extensionMinutes,
    };
  }

  // Computed properties
  bool get hasStarted => DateTime.now().isAfter(startTime);
  bool get hasEnded => DateTime.now().isAfter(endTime);
  bool get isLive => hasStarted && !hasEnded && isActive;

  Duration get timeRemaining {
    if (hasEnded) return Duration.zero;
    return endTime.difference(DateTime.now());
  }

  String get timeRemainingDisplay {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Ended';
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    }
    return '${remaining.inSeconds}s';
  }

  double get minimumBid {
    if (currentBid == null) return startingPrice;
    return currentBid! + bidIncrement;
  }

  bool get hasReserve => reservePrice != null;
  bool get hasBuyNow => buyNowPrice != null;
  bool get hasBids => bidCount > 0;
}

/// Bid placed on an auction
class MarketplaceBid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final double? maxAutoBid;
  final bool isWinning;
  final DateTime? outbidAt;
  final DateTime createdAt;

  // Joined fields
  final String? bidderName;

  MarketplaceBid({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    this.maxAutoBid,
    this.isWinning = false,
    this.outbidAt,
    required this.createdAt,
    this.bidderName,
  });

  factory MarketplaceBid.fromJson(Map<String, dynamic> json) {
    return MarketplaceBid(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      bidderId: json['bidder_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      maxAutoBid: (json['max_auto_bid'] as num?)?.toDouble(),
      isWinning: json['is_winning'] as bool? ?? false,
      outbidAt: json['outbid_at'] != null
          ? DateTime.parse(json['outbid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      bidderName: json['bidder_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'amount': amount,
      'max_auto_bid': maxAutoBid,
    };
  }

  bool get wasOutbid => outbidAt != null;
  bool get hasAutoBid => maxAutoBid != null;
}
