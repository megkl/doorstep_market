import 'dart:convert';

import 'package:http/http.dart' as http;

class MpesaService {
  final String consumerKey;
  final String consumerSecret;
  final String businessShortCode;
  final String passKey;
  final String callbackUrl;
  final bool useSandbox;
  final http.Client _httpClient;

  MpesaService({
    required this.consumerKey,
    required this.consumerSecret,
    required this.businessShortCode,
    required this.passKey,
    required this.callbackUrl,
    this.useSandbox = true,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  String get _oauthUrl {
    return useSandbox
        ? 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
        : 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
  }

  String get _stkPushUrl {
    return useSandbox
        ? 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'
        : 'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest';
  }

  Future<String> stkPush({
    required String phoneNumber,
    required String amount,
    String accountReference = 'DoorstepMarket',
    String transactionDesc = 'Doorstep Market order',
  }) async {
    final token = await _getAccessToken();
    final timestamp = _formatTimestamp(DateTime.now());
    final password = base64Encode(utf8.encode('$businessShortCode$passKey$timestamp'));

    final body = {
      'BusinessShortCode': businessShortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount,
      'PartyA': phoneNumber,
      'PartyB': businessShortCode,
      'PhoneNumber': phoneNumber,
      'CallBackURL': callbackUrl,
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc,
    };

    final response = await _httpClient.post(
      Uri.parse(_stkPushUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('MPesa STK push failed: ${response.statusCode} ${response.body}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    final resultCode = responseBody['ResponseCode']?.toString();
    if (resultCode == '0') {
      return responseBody['CustomerMessage']?.toString() ?? 'MPesa request initiated successfully.';
    }

    throw Exception('MPesa error: ${responseBody['errorMessage'] ?? response.body}');
  }

  Future<String> _getAccessToken() async {
    final basicAuth = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    final response = await _httpClient.get(
      Uri.parse(_oauthUrl),
      headers: {'Authorization': 'Basic $basicAuth'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to obtain MPesa access token: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  String _formatTimestamp(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$month$day$hour$minute$second';
  }
}
