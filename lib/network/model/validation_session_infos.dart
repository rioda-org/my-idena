
import 'dart:typed_data';
import 'package:my_idena/network/model/dictWords.dart';

class ValidationSessionInfoFlips {
  ValidationSessionInfoFlips(
      {this.hash,
      this.ready,
      this.extra,
      this.available,
      this.listWords,
      this.listImagesLeft,
      this.listImagesRight,
      this.answerType,
      this.relevanceType});

  String hash;
  bool ready;
  bool extra;
  bool available;
  List<Word> listWords;
  List<Uint8List> listImagesLeft;
  List<Uint8List> listImagesRight;
  int answerType;
  int relevanceType;
}

class ValidationSessionInfoContext {
  ValidationSessionInfoContext(
      {this.simulationMode, this.epochPeriod, this.checkFlipsQualityProcess});

  String epochPeriod;
  bool simulationMode;
  bool checkFlipsQualityProcess;
}

class ValidationSessionInfo {
  ValidationSessionInfo({this.typeSession, this.listSessionValidationFlips});

  String typeSession;
  List<ValidationSessionInfoFlips> listSessionValidationFlips;
  List<ValidationSessionInfoFlips> listSessionValidationFlipsExtra;
}
