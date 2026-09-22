class SignupResponse {
  final bool success;
  final String message;

  const SignupResponse({
    required this.success,
    required this.message,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}