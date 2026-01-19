
import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashNavigateToWelcome extends SplashState {}

class SplashNavigateToLogin extends SplashState {}

// class SplashUpdateAvailable extends SplashState {
//   final String downloadUrl;
//   final String status;
//   final String title;
//   final String content;
//   final String button1;
//   final String button2;

//   const SplashUpdateAvailable({
//     required this.downloadUrl,
//     required this.status,
//     required this.title,
//     required this.content,
//     required this.button1,
//     required this.button2,
//   });

//   @override
//   List<Object> get props => [downloadUrl, status, title, content, button1, button2];
// }
