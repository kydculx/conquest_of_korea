import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/colors.dart';
import '../widgets/tactical_app_bar.dart';

/// 나중에 플레이어가 기입할 외부 정책/약관 URL을 모바일 브라우저 렌더러로
/// 실시간 연동해 보여주는 하이테크 스타일 공통 웹뷰 스크린 컴포넌트입니다.
class PolicyWebviewScreen extends StatefulWidget {
  final String title;
  final String url;

  const PolicyWebviewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PolicyWebviewScreen> createState() => _PolicyWebviewScreenState();
}

class _PolicyWebviewScreenState extends State<PolicyWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(GameColors.tacticalBlack)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('⚠️ 웹뷰 리소스 에러: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: widget.title,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: GameColors.accentNeon,
                strokeWidth: 3.0,
              ),
            ),
        ],
      ),
    );
  }
}
