import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/logging.dart';
import 'package:instagram/widgets/barrier_progress_indicator.dart';
import 'package:instagram/widgets/haptic_feedback.dart';
import 'package:instagram/widgets/rounded_inkwell.dart';

class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  bool _isLoading = false;
  final List<XFile> _pickedImages = [];

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BarrierProgressIndicator(
      isActive: _isLoading,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _buildTextField(),
            ),
            _buildSelectedImages(),
            Container(height: 20),
            _buildShareButton(context),
          ],
        ),
        floatingActionButton: _buildPhotoButton(),
      ),
    );
  }

  Widget _buildSelectedImages() {
    const double itemSize = 60;
    return Container(
      height: itemSize,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 100),
        children: [
          for (final image in _pickedImages)
            _buildSelectedImage(
              image,
              itemSize,
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage(XFile image, double itemSize) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.network(image.path)
                : Image.file(
                    File(image.path),
                    width: itemSize,
                    height: itemSize,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(right: 16, top: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.close_rounded,
                size: 12,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _pickedImages.remove(image);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 80),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.orangeAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          Icons.photo_size_select_actual_outlined,
          color: Colors.white,
        ),
        onPressed: () async {
          logGoogleAnalyticsEvent(
            "photo_button_clicked",
            {
              "page": "write_page",
              "image_count": _pickedImages.length,
            },
          );

          if (_pickedImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('이미지는 최대 1개까지 선택 가능합니다.'),
            ));
            InstagramHaptic.error();
            return;
          }

          // 사진첩에서 사진 선택
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

          // 선택한 파일이 없으면 종료
          if (pickedFile == null) exit(0);

          setState(() {
            _pickedImages.add(pickedFile);
          });
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF1F2F3),
      title: const Text(
        '새 게시물',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      expands: true,
      minLines: null,
      maxLines: null,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        hintText: '문구를 작성하거나 설문을 추가하세요...',
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.black45,
        ),
        border: InputBorder.none,
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SafeArea(
      child: RoundedInkWell(
        onTap: () {
          if (_textController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('게시물을 입력해주세요.'),
            ));
            InstagramHaptic.error();
            return;
          }
          _uploadPost(context);
        },
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _textController.text.isEmpty ? Colors.black26 : Color(0xFF4B61EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '공유',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPost(BuildContext context) async {
    // TextField가 비어있으면 게시물을 업로드하지 않음
    if (_textController.text.isEmpty) return;

    // 필요시 사진 업로드
    String? imageUrl = await _uploadImage(context);

    // Firestore의 posts 컬렉션에 게시물 추가하기
    final newPost = {
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'username': FirebaseAuth.instance.currentUser?.displayName,
      'description': _textController.text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'imageUrl': imageUrl,
    };
    await FirebaseFirestore.instance.collection('posts').add(newPost);

    // TextField 초기화
    _textController.clear();

    // Google Analytics 이벤트 로깅
    await logGoogleAnalyticsEvent(
      "write",
      {
        "page": "write_page",
        "image_count": _pickedImages.length,
      },
    );

    // 이전 페이지로 이동
    Navigator.pop(context);
  }

  Future<String?> _uploadImage(BuildContext context) async {
    try {
      setState(() => _isLoading = true);

      final pickedFile = _pickedImages.firstOrNull;

      // 선택한 파일이 없다면 종료
      if (pickedFile == null) {
        return null;
      }

      // Storage에 업로드할 위치 설정하기
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final String pathName = '/user/$uid/$fileName';

      // Storage에 업로드
      await FirebaseStorage.instance.ref(pathName).putData(
            await pickedFile.readAsBytes(),
            SettableMetadata(
              contentType: pickedFile.mimeType,
            ),
          );

      // 업로드된 파일의 URL 가져오기
      String downloadURL = await FirebaseStorage.instance.ref(pathName).getDownloadURL();
      return downloadURL;
    } catch (e) {
      // 오류 처리
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('이미지 업로드에 실패했습니다.'),
      ));
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
