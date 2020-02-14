// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheObjectAdapter extends TypeAdapter<CacheObject> {
  @override
  final typeId = 0;

  @override
  CacheObject read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheObject(
      fields[1] as String,
      relativePath: fields[2] as String,
      validTill: fields[3] as DateTime,
      eTag: fields[4] as String,
      id: fields[0] as int,
    )..touched = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CacheObject obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.relativePath)
      ..writeByte(3)
      ..write(obj.validTill)
      ..writeByte(4)
      ..write(obj.eTag)
      ..writeByte(5)
      ..write(obj.touched);
  }
}
