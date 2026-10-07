// Admin data for the dashboard and the three admin tools.
//
// Everything here is SAMPLE data held in memory so the screens can be tried out.
// TODO: replace each method with a real call to the backend (and keep the
// method names, so the screens do not need to change).

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
}

/// A check (ID, SAPS, address...) a user has submitted and is waiting to be verified.
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
}

/// A review waiting to be approved (or removed) before it is shown on a profile.
class ReviewItem {
  final int id;
  final String reviewerName;
  final String reviewerRole; // 'SITTER' or 'HOMEOWNER'
  final String revieweeName;
  final double rating;
  final String comment;
  final String date;
  final String? flagReason; // set when another user reported the review

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
}

/// A request from a homeowner or sitter to cancel a booking.
class CancellationRequest {
  final int id;
  final String bookingTitle;
  final String dates;
  final String homeownerName;
  final String sitterName;
  final String requestedBy; // 'Homeowner' or 'Sitter'
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
}

class AdminService {
  // ---------- Sample data ----------

  static const int _sitters = 47;
  static const int _homeowners = 81;

  static final List<UserCheck> _checks = [
    const UserCheck(
      id: 1,
      userName: 'Thabo Mokoena',
      role: 'SITTER',
      checkType: 'SAPS Police Clearance',
      detail: 'Certificate uploaded',
      submittedOn: 'Oct 4',
    ),
    const UserCheck(
      id: 2,
      userName: 'Joshua Stevens',
      role: 'HOMEOWNER',
      checkType: 'Identity / SA ID',
      detail: 'ID photo uploaded',
      submittedOn: 'Oct 5',
    ),
    const UserCheck(
      id: 3,
      userName: 'Claire Vance',
      role: 'HOMEOWNER',
      checkType: 'Home Address / Proof of Residence',
      detail: '12 Main Road, Rondebosch',
      submittedOn: 'Oct 3',
    ),
    const UserCheck(
      id: 4,
      userName: 'Lerato Khumalo',
      role: 'SITTER',
      checkType: 'Identity / SA ID',
      detail: 'ID photo uploaded',
      submittedOn: 'Oct 2',
    ),
    const UserCheck(
      id: 5,
      userName: 'Thandi Mokoena',
      role: 'HOMEOWNER',
      checkType: 'Emergency Contact Details',
      detail: '+27 82 123 4567',
      submittedOn: 'Oct 1',
    ),
  ];

  static final List<ReviewItem> _reviews = [
    const ReviewItem(
      id: 1,
      reviewerName: 'Joshua Stevens',
      reviewerRole: 'HOMEOWNER',
      revieweeName: 'Sarah Jenkins',
      rating: 5.0,
      comment: 'Sarah was brilliant with Buster! Daily updates and everything spotless.',
      date: 'Oct 4',
    ),
    const ReviewItem(
      id: 2,
      reviewerName: 'Michael Tau',
      reviewerRole: 'SITTER',
      revieweeName: 'Claire Vance',
      rating: 1.0,
      comment: 'Terrible host, would not recommend to anyone.',
      date: 'Oct 3',
      flagReason: 'Reported as unfair by the homeowner',
    ),
    const ReviewItem(
      id: 3,
      reviewerName: 'Claire Vance',
      reviewerRole: 'HOMEOWNER',
      revieweeName: 'Michael Tau',
      rating: 4.5,
      comment: 'Reliable and friendly. Would book again.',
      date: 'Oct 2',
    ),
  ];

  static final List<CancellationRequest> _cancellations = [
    const CancellationRequest(
      id: 1,
      bookingTitle: 'Camps Bay Stay',
      dates: 'Oct 12 – 18',
      homeownerName: 'Joshua Stevens',
      sitterName: 'Lerato Khumalo',
      requestedBy: 'Homeowner',
      reason: 'Family emergency, I need to cancel the trip.',
      requestedOn: 'Oct 5',
    ),
    const CancellationRequest(
      id: 2,
      bookingTitle: 'Claremont Cottage',
      dates: 'Nov 24 – 27',
      homeownerName: 'Claire Vance',
      sitterName: 'Michael Tau',
      requestedBy: 'Sitter',
      reason: 'I was double booked by mistake.',
      requestedOn: 'Oct 6',
    ),
    const CancellationRequest(
      id: 3,
      bookingTitle: 'Constantia Villa',
      dates: 'Dec 15 – 20',
      homeownerName: 'Thandi Mokoena',
      sitterName: 'Jessica Daniels',
      requestedBy: 'Homeowner',
      reason: 'Plans changed.',
      requestedOn: 'Oct 6',
    ),
  ];

  // ---------- Dashboard ----------

  static Future<AdminStats> fetchStats() async {
    // TODO: load the real counts from the backend.
    return AdminStats(
      totalUsers: _sitters + _homeowners,
      sitters: _sitters,
      homeowners: _homeowners,
      ongoingBookings: 6,
      acceptedBookings: 9,
      searchingBookings: 4,
      completedBookings: 112,
      pendingChecks: _checks.length,
      pendingReviews: _reviews.length,
      cancellationRequests: _cancellations.length,
    );
  }

  // ---------- User checks verifier ----------

  static Future<List<UserCheck>> fetchPendingChecks() async => List.of(_checks);

  /// Approving marks the check as verified; rejecting asks the user to resubmit.
  static Future<void> resolveCheck(int id, {required bool approved, String? reason}) async {
    // TODO: update the check's status in the backend (and save the reason).
    _checks.removeWhere((c) => c.id == id);
  }

  // ---------- Review verifier ----------

  static Future<List<ReviewItem>> fetchPendingReviews() async => List.of(_reviews);

  /// Approving publishes the review; rejecting removes it.
  static Future<void> resolveReview(int id, {required bool approved}) async {
    // TODO: update the review in the backend.
    _reviews.removeWhere((r) => r.id == id);
  }

  // ---------- Cancellations ----------

  static Future<List<CancellationRequest>> fetchCancellationRequests() async =>
      List.of(_cancellations);

  /// Approving cancels the booking for both people; declining keeps the booking.
  static Future<void> resolveCancellation(int id, {required bool approved}) async {
    // TODO: cancel the booking (and notify both people) in the backend.
    _cancellations.removeWhere((c) => c.id == id);
  }
}