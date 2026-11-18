import 'package:day_log/core/services/api_service.dart';
import 'package:day_log/core/services/server_address_storage_service.dart';
import 'package:day_log/core/theme/app_color.dart';
import 'package:day_log/core/utils/snack_bar_helper.dart';
import 'package:day_log/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class DevModeScreen extends StatefulWidget {
  const DevModeScreen({super.key});

  @override
  State<DevModeScreen> createState() => _DevModeScreenState();
}

class _DevModeScreenState extends State<DevModeScreen> {
  //저장된 서버 주소 관리
  final ServerAddressStorageService _storageService =
  ServerAddressStorageService();

  //서버 주소 입력창
  final TextEditingController _addressController = TextEditingController();

  //학습 결과 웹 주소 입력창 (QR 주소 확인에 사용)
  final TextEditingController _resultWebController = TextEditingController();

  //저장된 주소 확인 중 여부
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _resultWebController.dispose();
    super.dispose();
  }

  //저장된 서버 주소 불러오기
  Future<void> _loadSavedAddress() async {
    String address = ApiService.defaultServerAddress;
    String resultWebOrigin = ApiService.defaultResultWebOrigin;

    try {
      final saved = await _storageService.readServerAddress();

      if (saved != null && saved.trim().isNotEmpty) {
        address = saved;
      }

      final savedWeb = await _storageService.readResultWebOrigin();

      if (savedWeb != null && savedWeb.trim().isNotEmpty) {
        resultWebOrigin = savedWeb;
      }
    } catch (e) {
      //읽지 못하면 기본 주소 사용
      print('서버 주소 읽기 오류: $e');
    }

    if (!mounted) return;

    _addressController.text = address;
    _resultWebController.text = resultWebOrigin;

    setState(() {
      _isLoading = false;
    });
  }

  //주소를 적용하고 스플래시 화면으로 이동
  Future<void> _applyAndContinue() async {
    //공백, 끝의 /, 끝의 /api/v1 제거
    final address = _addressController.text
        .trim()
        .replaceAll(RegExp(r'/+$'), '')
        .replaceFirst(RegExp(r'/api/v1$'), '');

    //공백, 끝의 /, 끝의 /results 제거
    final resultWebOrigin = _resultWebController.text
        .trim()
        .replaceAll(RegExp(r'/+$'), '')
        .replaceFirst(RegExp(r'/results$'), '');

    if (!_isHttpAddress(address)) {
      SnackBarHelper.show(
        context,
        '주소 형식이 올바르지 않아요. 예: http://10.0.2.2:8000',
      );
      return;
    }

    //QR 주소와 비교하므로 경로 없이 주소와 포트까지만 허용
    if (!_isHttpAddress(resultWebOrigin) ||
        Uri.parse(resultWebOrigin).path.isNotEmpty) {
      SnackBarHelper.show(
        context,
        '학습 결과 웹 주소 형식이 올바르지 않아요. 예: http://10.0.2.2:3000',
      );
      return;
    }

    //이번 실행에 바로 적용
    ApiService.changeServerAddress(address);
    ApiService.changeResultWebOrigin(resultWebOrigin);

    try {
      //다음 실행에도 쓰도록 저장
      await _storageService.saveServerAddress(address);
      await _storageService.saveResultWebOrigin(resultWebOrigin);
    } catch (e) {
      //저장에 실패해도 이번 실행에는 적용됨
      print('서버 주소 저장 오류: $e');
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  //http 또는 https 주소인지 확인
  bool _isHttpAddress(String address) {
    final uri = Uri.tryParse(address);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  //주소 입력창 공통 꾸밈
  InputDecoration _addressDecoration({
    required String labelText,
    required String hintText,
    required String helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: AppColor.surfaceCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColor.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppColor.primary),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // 1. 제목과 안내
              const Text(
                '개발자 모드',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '연결할 서버 주소와 학습 결과 웹 주소를\n확인하고 다음으로 넘어가요.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColor.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // 2. 서버 주소 입력
              TextField(
                controller: _addressController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: _addressDecoration(
                  labelText: '서버 주소',
                  hintText: ApiService.defaultServerAddress,
                  helperText: '이 주소 뒤에 /api/v1을 붙여서 요청해요.',
                ),
              ),

              const SizedBox(height: 16),

              // 3. 학습 결과 웹 주소 입력
              TextField(
                controller: _resultWebController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: _addressDecoration(
                  labelText: '학습 결과 웹 주소',
                  hintText: ApiService.defaultResultWebOrigin,
                  helperText: '이 주소로 시작하는 학습 결과 QR만 인식해요.',
                ),
              ),

              const SizedBox(height: 8),

              // 4. 기본 주소로 되돌리기
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.textSecondary,
                  ),
                  onPressed: () {
                    _addressController.text =
                        ApiService.defaultServerAddress;
                    _resultWebController.text =
                        ApiService.defaultResultWebOrigin;
                  },
                  child: const Text('기본 주소로 되돌리기'),
                ),
              ),

              const SizedBox(height: 16),

              // 5. 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _applyAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '이 주소로 시작',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}