// CacheManager for Flutter
// Copyright (c) 2017 Rene Floor
// Released under MIT License.

// HINT: Unnecessary import. Future and Stream are available via dart:core.
import 'dart:async';

import 'package:hive/hive.dart';

part 'cache_object.g.dart';

final String tableCacheObject = "cacheObject";

final String columnId = "_id";
final String columnUrl = "url";
final String columnPath = "relativePath";
final String columnETag = "eTag";
final String columnValidTill = "validTill";
final String columnTouched = "touched";
/**
 *  Flutter Cache Manager
 *
 *  Copyright (c) 2018 Rene Floor
 *
 *  Released under MIT License.
 */

///Cache information of one file
///

@HiveType(typeId: 0)
class CacheObject extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String relativePath;

  @HiveField(3)
  DateTime validTill;

  @HiveField(4)
  String eTag;

  @HiveField(5)
  DateTime touched;

  CacheObject(
    this.url, {
    this.relativePath,
    this.validTill,
    this.eTag,
    this.id,
  }) {
    touched = DateTime.now();
  }
}

class CacheObjectProvider {
  Box<CacheObject> objects;

  Future open() async {
    objects = await Hive.openBox<CacheObject>('image_cache');
  }

  Future<dynamic> updateOrInsert(CacheObject cacheObject) async {
    if (cacheObject.id == null) {
      return await insert(cacheObject);
    } else {
      return await update(cacheObject);
    }
  }

  Future<CacheObject> insert(CacheObject cacheObject) async {
    final id = await objects.add(cacheObject);
    cacheObject.id = id;
    await cacheObject.save();
    return cacheObject;
  }

  Future<CacheObject> get(String url) async {
    try {
      return objects.values.firstWhere((e) => e.url == url);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(CacheObject object) async {
    return object.delete();
  }

  Future deleteAll(Iterable<CacheObject> o) async {
    final futures = o.map((e) => e.delete()).toList();
    return Future.wait(futures);
  }

  Future<void> update(CacheObject cacheObject) async {
    return cacheObject.save();
  }

  Future<List<CacheObject>> getAllObjects() async {
    return objects.values;
  }

  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    final arg =
        DateTime.now().subtract(new Duration(days: 1)).millisecondsSinceEpoch;
    return objects.values
        .where((e) => e.touched.millisecondsSinceEpoch < arg)
        .skip(capacity)
        .take(100)
        .toList();
  }

  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {
    final arg = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return objects.values
        .where((e) => e.touched.millisecondsSinceEpoch < arg)
        .toList();
  }
}
