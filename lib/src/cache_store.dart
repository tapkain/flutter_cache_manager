import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/src/cache_object.dart';
import 'package:flutter_cache_manager/src/file_info.dart';
import 'package:path/path.dart' as p;

///Flutter Cache Manager
///Copyright (c) 2019 Rene Floor
///Released under MIT License.

class CacheStore {
  Map<String, Future<CacheObject>> _futureCache = new Map();
  Map<String, CacheObject> _memCache = new Map();

  Future<String> filePath;
  String _filePath;

  Future<CacheObjectProvider> _cacheObjectProvider;
  String storeKey;

  final int _capacity;
  final Duration _maxAge;

  DateTime lastCleanupRun = DateTime.now();
  static const Duration cleanupRunMinInterval = Duration(seconds: 10);
  Timer _scheduledCleanup;

  CacheStore(
      Future<String> basePath, this.storeKey, this._capacity, this._maxAge) {
    filePath = basePath;
    basePath.then((p) => _filePath = p);

    _cacheObjectProvider = _getObjectProvider();
  }

  Future<CacheObjectProvider> _getObjectProvider() async {
    final provider = CacheObjectProvider();
    await provider.open();
    return provider;
  }

  Future<FileInfo> getFile(String url) async {
    var cacheObject = await retrieveCacheData(url);
    if (cacheObject == null || cacheObject.relativePath == null) {
      return null;
    }
    var path = p.join(await filePath, cacheObject.relativePath);
    return new FileInfo(
        File(path), FileSource.Cache, cacheObject.validTill, url);
  }

  putFile(CacheObject cacheObject) async {
    _memCache[cacheObject.url] = cacheObject;
    await _updateCacheDataInDatabase(cacheObject);
  }

  Future<CacheObject> retrieveCacheData(String url) {
    if (_memCache.containsKey(url)) {
      return Future.value(_memCache[url]);
    }
    if (!_futureCache.containsKey(url)) {
      var completer = new Completer<CacheObject>();
      _getCacheDataFromDatabase(url).then((cacheObject) async {
        if (cacheObject != null && !await _fileExists(cacheObject)) {
          final provider = await _cacheObjectProvider;
          provider.delete(cacheObject);
          cacheObject = null;
        }
        completer.complete(cacheObject);

        _memCache[url] = cacheObject;
        _futureCache[url] = null;
      });

      _futureCache[url] = completer.future;
    }
    return _futureCache[url];
  }

  FileInfo getFileFromMemory(String url) {
    if (_memCache[url] == null || _filePath == null) {
      return null;
    }
    var cacheObject = _memCache[url];

    var path = p.join(_filePath, cacheObject.relativePath);
    return new FileInfo(
        File(path), FileSource.Cache, cacheObject.validTill, url);
  }

  Future<bool> _fileExists(CacheObject cacheObject) async {
    if (cacheObject?.relativePath == null) {
      return false;
    }
    return new File(p.join(await filePath, cacheObject.relativePath)).exists();
  }

  Future<CacheObject> _getCacheDataFromDatabase(String url) async {
    var provider = await _cacheObjectProvider;
    var data = await provider.get(url);
    if (await _fileExists(data)) {
      _updateCacheDataInDatabase(data);
    }
    _scheduleCleanup();
    return data;
  }

  void _scheduleCleanup() {
    if (_scheduledCleanup != null) {
      return;
    }
    _scheduledCleanup = Timer(cleanupRunMinInterval, () {
      _scheduledCleanup = null;
      _cleanupCache();
    });
  }

  Future<dynamic> _updateCacheDataInDatabase(CacheObject cacheObject) async {
    var provider = await _cacheObjectProvider;
    var data = await provider.updateOrInsert(cacheObject);
    return data;
  }

  Future<void> _cleanupCache() async {
    var provider = await _cacheObjectProvider;
    var overCapacity = await provider.getObjectsOverCapacity(_capacity);
    var oldObjects = await provider.getOldObjects(_maxAge);

    var toRemove = List<CacheObject>();
    overCapacity.forEach((cacheObject) async {
      _removeCachedFile(cacheObject, toRemove);
    });
    oldObjects.forEach((cacheObject) async {
      _removeCachedFile(cacheObject, toRemove);
    });

    await provider.deleteAll(toRemove);
  }

  emptyCache({bool files = true}) async {
    var provider = await _cacheObjectProvider;
    var toRemove = List<CacheObject>();

    var allObjects = await provider.getAllObjects();
    allObjects.forEach((cacheObject) async {
      _removeCachedFile(cacheObject, toRemove, files: files);
    });

    await provider.deleteAll(toRemove);
  }

  removeCachedFile(CacheObject cacheObject, {bool files = true}) async {
    var provider = await _cacheObjectProvider;
    var toRemove = List<CacheObject>();
    _removeCachedFile(cacheObject, toRemove, files: files);
    await provider.deleteAll(toRemove);
  }

  _removeCachedFile(CacheObject cacheObject, List<CacheObject> toRemove,
      {bool files = true}) async {
    if (toRemove.where((e) => e.id == cacheObject.id).length == 0) {
      toRemove.add(cacheObject);
      if (_memCache.containsKey(cacheObject.url))
        _memCache.remove(cacheObject.url);
      if (_futureCache.containsKey(cacheObject.url))
        _futureCache.remove(cacheObject.url);
    }

    if (!files) {
      return;
    }

    var file = new File(p.join(await filePath, cacheObject.relativePath));
    if (await file.exists()) {
      file.delete();
    }
  }
}
