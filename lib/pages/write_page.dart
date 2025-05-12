import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WritePage extends StatelessWidget {
  WritePage({super.key});

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildTextField()),
          Container(height: 20),
          _buildShareButton(context),
        ],
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
        hintStyle: TextStyle(fontSize: 14, color: Colors.black45),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          _uploadPost(context);
        },
        child: Container(
          margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Color(0xFF4B61EF),
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
      ),
    );
  }

  // 사진첩에서 사진을 선택하고 Storage에 업로드하여 이미지 URL을 반환합니다.
  Future<String?> _uploadImage(BuildContext context) async {
    try {
      // 사진첩에서 사진 선택
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      // 선택한 파일이 없다면 종료
      if (pickedFile == null) return null;

      // Storage에 업로드할 위치 설정하기
      // 사용자 uid 가져오기
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 임의의 파일 이름 설정하기 (파일명이 서로 겹치지 않는 것이 중요함)
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Storage에 업로드할 위치 설정하기 (uid와 fileName의 조합)
      final String pathName = '/user/$uid/$fileName';

      // Storage에 업로드
      FirebaseStorage.instance
          .ref(pathName)
          .putData(
            await pickedFile.readAsBytes(),
            SettableMetadata(contentType: "image/jpeg"),
          );

      // 업로드된 파일의 URL 가져오기
      final uploadedUrl =
          await FirebaseStorage.instance.ref(pathName).getDownloadURL();
      print(uploadedUrl);
      // 업로드된 파일의 URL 반환
      return uploadedUrl;
    } catch (e) {
      // 오류 처리
      print(e);
      return null;
    }
  }

  Future<void> _uploadPost(BuildContext context) async {
    // TextField가 비어있으면 게시물을 업로드하지 않음
    if (_textController.text.isEmpty) return;

    // 사진첩에서 사진 선택 및 업로드
    String? imageUrl = await _uploadImage(context);

    final newPost = {
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'username': FirebaseAuth.instance.currentUser?.displayName,
      'description': _textController.text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'imageUrl': imageUrl,
    };

    // Firestore의 posts 컬렉션에 게시물 추가하기
    await FirebaseFirestore.instance.collection("posts").add(newPost);

    // TextField 초기화
    _textController.clear();

    // 이전 페이지로 이동
    Navigator.of(context).pop();
  }
}
