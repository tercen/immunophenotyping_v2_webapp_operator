
import 'package:json_annotation/json_annotation.dart';

part 'qc_channels.g.dart';

@JsonSerializable()
class QcChannels {
  final List<String> channels;

  QcChannels({required this.channels});

  factory QcChannels.fromJson(Map<String, dynamic> json) =>
      _$QcChannelsFromJson(json);

  Map<String, dynamic> toJson() => _$QcChannelsToJson(this);
}