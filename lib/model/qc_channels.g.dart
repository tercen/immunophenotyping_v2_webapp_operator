// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_channels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QcChannels _$QcChannelsFromJson(Map<String, dynamic> json) => QcChannels(
      channels:
          (json['channels'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$QcChannelsToJson(QcChannels instance) =>
    <String, dynamic>{
      'channels': instance.channels,
    };
