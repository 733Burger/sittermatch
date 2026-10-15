import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AdminStats {
  final int totalUsers;
  final int sitters;
  final int homeowners;
  final int ongoingBookings;
  final int acceptedBookings;
  final int searchingBookings;
  final int completedBookings;
  final int pendingChecks;
  final int pendingReviews;
  final int cancellationRequests;

  const AdminStats({
    required this.totalUsers,
    required this.sitters,
    required this.homeowners,
    required this.ongoingBookings,
    required this.acceptedBookings,
    required this.searchingBookings,
    required this.completedBookings,
    required this.pendingChecks,
    required this.pendingReviews,
    required this.cancellationRequests,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      sitters: json['sitters'] ?? 0,
      homeowners: json['homeowners'] ?? 0,
      ongoingBookings: json['ongoingBookings'] ?? 0,
      acceptedBookings: json['acceptedBookings'] ?? 0,
      searchingBookings: json['searchingBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      pendingChecks: json['pendingChecks'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      cancellationRequests: json['cancellationRequests'] ?? 0,
    );
  }
}

class UserCheck {
  final int id;
  final String userName;
  final String role; // 'SITTER' or 'HOMEOWNER'
  final String checkType;
  final String detail;
  final String submittedOn;

  const UserCheck({
    required this.id,
    required this.userName,
    required this.role,
    required this.checkType,
    required this.detail,
    required this.submittedOn,
  });

  factory UserCheck.fromJson(Map<String, dynamic> json) {
    return UserCheck(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? 'Unknown',
      role: json['role'] ?? 'SITTER',
      checkType: json['checkType'] ?? 'Identity Verification',
      detail: json['detail'] ?? '',
      submittedOn: json['submittedOn'] ?? 'Recently',
    );
  }
}

class ReviewItem {
  final int id;
  final String reviewerName;
  final String reviewerRole;
  final String revieweeName;
  final double rating;
  final String comment;
  final String date;
  final String? flagReason;

  const ReviewItem({
    required this.id,
    required this.reviewerName,
    required this.reviewerRole,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.date,
    this.flagReason,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] ?? 0,
      reviewerName: json['reviewerName'] ?? '',
      reviewerRole: json['reviewerRole'] ?? '',
      revieweeName: json['revieweeName'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: json['date'] ?? '',
      flagReason: json['flagReason'],
    );
  }
}

class CancellationRequest {
  final int id;
  final String bookingTitle;
  final String dates;
  final String homeownerName;
  final String sitterName;
  final String requestedBy;
  final String reason;
  final String requestedOn;

  const CancellationRequest({
    required this.id,
    required this.bookingTitle,
    required this.dates,
    required this.homeownerName,
    required this.sitterName,
    required this.requestedBy,
    required this.reason,
    required this.requestedOn,
  });

  factory CancellationRequest.fromJson(Map<String, dynamic> json) {
    return CancellationRequest(
      id: json['id'] ?? 0,
      bookingTitle: json['bookingTitle'] ?? '',
      dates: json['dates'] ?? '',
      homeownerName: json['homeownerName'] ?? '',
      sitterName: json['sitterName'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      reason: json['reason'] ?? '',
      requestedOn: json['requestedOn'] ?? '',
    );
  }
}

class AdminService {
  static final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);

  // ---------- Dashboard ----------

    static Future<AdminStats> fetchStats() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/admin/stats'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Could not load stats (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;

    // Fetch live list lengths to guarantee absolute accuracy
    final checks = await fetchPendingChecks();
    final reviews = await fetchPendingReviews();
    final cancellations = await fetchCancellationRequests();

    return AdminStats(
      totalUsers: read('totalUsers'),
      sitters: read('sitters'),
      homeowners: read('homeowners'),
      pendingChecks: checks.length, // <-- Updated to use actual fetched checks count
      ongoingBookings: read('ongoingBookings'),
      acceptedBookings: read('acceptedBookings'),
      searchingBookings: read('searchingBookings'),
      completedBookings: read('completedBookings'),
      pendingReviews: reviews.length,
      cancellationRequests: cancellations.length,
    );
  }

  // ---------- User checks verifier ----------

  static Future<List<UserCheck>> fetchPendingChecks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/pending-checks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => UserCheck.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pending checks: $e');
      return [];
    }
  }

  /// Approving marks the check as verified; rejecting asks the user to resubmit.
  static Future<void> resolveCheck(int id, {required bool approved, String? reason}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/admin/resolve-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'checkId': id,
          'approved': approved,
          'reason': reason ?? '',
        }),
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('Error resolving check: $e');
    }
  }

  // ---------- Review verifier ----------

  static Future<List<ReviewItem>> fetchPendingReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/pending-reviews'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ReviewItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pending reviews: $e');
      return [];
    }
  }

  static Future<void> resolveReview(int id, {required bool approved}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/admin/resolve-review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reviewId': id, 'approved': approved}),
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('Error resolving review: $e');
    }
  }

  // ---------- Cancellations ----------

  static Future<List<CancellationRequest>> fetchCancellationRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/cancellation-requests'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CancellationRequest.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cancellation requests: $e');
      return [];
    }
  }

  static Future<void> resolveCancellation(int id, {required bool approved}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/admin/resolve-cancellation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestId': id, 'approved': approved}),
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('Error resolving cancellation: $e');
    }
  }
}