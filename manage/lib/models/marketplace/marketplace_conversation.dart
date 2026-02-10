import 'marketplace_enums.dart';

/// Inquiry sent from buyer to seller
class MarketplaceInquiry {
  final String id;
  final String listingId;
  final String buyerId;
  final String message;
  final double? offeredPrice;
  final InquiryStatus status;
  final String? responseMessage;
  final DateTime? respondedAt;
  final bool contactRevealed;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? listingTitle;
  final String? sellerName;
  final String? buyerName;

  MarketplaceInquiry({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.message,
    this.offeredPrice,
    this.status = InquiryStatus.pending,
    this.responseMessage,
    this.respondedAt,
    this.contactRevealed = false,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.sellerName,
    this.buyerName,
  });

  factory MarketplaceInquiry.fromJson(Map<String, dynamic> json) {
    return MarketplaceInquiry(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      message: json['message'] as String,
      offeredPrice: (json['offered_price'] as num?)?.toDouble(),
      status: InquiryStatus.fromString(json['status'] as String? ?? 'pending'),
      responseMessage: json['response_message'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      contactRevealed: json['contact_revealed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      listingTitle: json['listing_title'] as String?,
      sellerName: json['seller_name'] as String?,
      buyerName: json['buyer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'buyer_id': buyerId,
      'message': message,
      'offered_price': offeredPrice,
    };
  }
}

/// Conversation between buyer and seller
class MarketplaceConversation {
  final String id;
  final String listingId;
  final String? inquiryId;
  final String buyerId;
  final String sellerId;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int buyerUnreadCount;
  final int sellerUnreadCount;
  final bool isActive;
  final bool buyerArchived;
  final bool sellerArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? listingTitle;
  final String? listingSpecies;
  final double? listingPrice;
  final String? listingPhoto;
  final String? listingStatus;
  final String? buyerName;
  final String? sellerName;

  MarketplaceConversation({
    required this.id,
    required this.listingId,
    this.inquiryId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.buyerUnreadCount = 0,
    this.sellerUnreadCount = 0,
    this.isActive = true,
    this.buyerArchived = false,
    this.sellerArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.listingSpecies,
    this.listingPrice,
    this.listingPhoto,
    this.listingStatus,
    this.buyerName,
    this.sellerName,
  });

  factory MarketplaceConversation.fromJson(Map<String, dynamic> json) {
    return MarketplaceConversation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      inquiryId: json['inquiry_id'] as String?,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      lastMessageText: json['last_message_text'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      buyerUnreadCount: json['buyer_unread_count'] as int? ?? 0,
      sellerUnreadCount: json['seller_unread_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      buyerArchived: json['buyer_archived'] as bool? ?? false,
      sellerArchived: json['seller_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      listingTitle: json['listing_title'] as String?,
      listingSpecies: json['listing_species'] as String?,
      listingPrice: (json['listing_price'] as num?)?.toDouble(),
      listingPhoto: json['listing_photo'] as String?,
      listingStatus: json['listing_status'] as String?,
      buyerName: json['buyer_name'] as String?,
      sellerName: json['seller_name'] as String?,
    );
  }

  int getUnreadCount(String currentUserId) {
    if (currentUserId == buyerId) return buyerUnreadCount;
    if (currentUserId == sellerId) return sellerUnreadCount;
    return 0;
  }

  String getOtherPartyName(String currentUserId) {
    if (currentUserId == buyerId) return sellerName ?? 'Seller';
    return buyerName ?? 'Buyer';
  }

  bool isArchived(String currentUserId) {
    if (currentUserId == buyerId) return buyerArchived;
    return sellerArchived;
  }
}

/// Message in a conversation
class MarketplaceMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType messageType;
  final double? offeredPrice;
  final OfferStatus? offerStatus;
  final List<String>? attachmentUrls;
  final DateTime? readAt;
  final DateTime createdAt;

  MarketplaceMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.messageType = MessageType.text,
    this.offeredPrice,
    this.offerStatus,
    this.attachmentUrls,
    this.readAt,
    required this.createdAt,
  });

  factory MarketplaceMessage.fromJson(Map<String, dynamic> json) {
    return MarketplaceMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: MessageType.fromString(json['message_type'] as String?),
      offeredPrice: (json['offered_price'] as num?)?.toDouble(),
      offerStatus: OfferStatus.fromString(json['offer_status'] as String?),
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)
          ?.cast<String>(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.name,
      'offered_price': offeredPrice,
      'offer_status': offerStatus?.name,
      'attachment_urls': attachmentUrls,
    };
  }

  bool get isOffer => messageType == MessageType.offer;
  bool get isRead => readAt != null;
}
