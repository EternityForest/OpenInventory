import 'package:shared_storage/saf.dart' as saf;

Uri? selectedRoot;


int s = DateTime.now().millisecondsSinceEpoch;

void pr(String t)
{
  print(t);
  print(DateTime.now().millisecondsSinceEpoch - s);
  s = DateTime.now().millisecondsSinceEpoch;
  print(" ");
}


Future<saf.UriPermission?> _getAndroidFolder() async {
  var f = await saf.persistedUriPermissions();

  if (f == null || f.isEmpty) {
    await saf.openDocumentTree(grantWritePermission: true);
  } else {
    var files = await saf.listFiles(f[0].uri, columns: [
      saf.DocumentFileColumn.id,
      saf.DocumentFileColumn.displayName
    ]).toList();
    if (files.isEmpty) {
      // This is quite likely because the permissions are messed up,
      //so lets start over
      for (var i
          in await saf.persistedUriPermissions() ?? <saf.UriPermission>[]) {
        saf.releasePersistableUriPermission(i.uri);
      }
      await saf.openDocumentTree(grantWritePermission: true);

      // Now if it's empty make a dummy so this doesn't happen again
      var f = await saf.persistedUriPermissions();

      if (f == null || f.isEmpty) {
        selectedRoot = null;
        return null;

      }
      var files = await saf.listFiles(f[0].uri, columns: [
        saf.DocumentFileColumn.id,
        saf.DocumentFileColumn.displayName
      ]).toList();
      if (files.isEmpty) {
        saf.createFileAsString(f[0].uri,
            mimeType: "text/json", displayName: "invrepo.json", content: "{}");
      }
    }
  }

  //User may have selected a SAF tree by now
  f = await saf.persistedUriPermissions();

  if (f == null || f.isEmpty) {
    selectedRoot = null;
    return null;
  }
  selectedRoot = f[0].uri;
  return f[0];
}

void changeAndroidFolder() async {
  for (var i in await saf.persistedUriPermissions() ?? <saf.UriPermission>[]) {
    saf.releasePersistableUriPermission(i.uri);
  }
  await getAndroidFolder();
}

Future<saf.UriPermission?> getAndroidFolder() async {
  try {
    return await _getAndroidFolder();
  } catch (e) {
    changeAndroidFolder();
    return await (_getAndroidFolder());
  }
}

// Implement something resembling a terrible version of UNIX
// Atomic rename on top of the terrible SAF.
Future<void> saveStr(String fn, String d) async {
  Uri? root = selectedRoot;

  var pl = fn.split("/").toList();

  var pl2 = pl.getRange(0, pl.length - 1);

  var basename = pl.last;

  for (var i in pl2) {
    if (i == '') {
      continue;
    }
    if (root == null) {
      throw Error();
    }

    var y = await saf.child(root, i);
    if (y == null) {
      y = await saf.createDirectory(root, i);
      if (y == null) {
        throw Error();
      }
    }

    root = y.uri;
  }

  if (root == null) {
    throw Error();
  }

  saf.DocumentFile? x = await saf.createFileAsString(root,
      mimeType: "text/json", displayName: "$basename~", content: d);

  if (x == null) {
    throw Error();
  }

  var y = await saf.child(root, basename);
  if (y != null) {
    await y.delete();
  }

  x.renameTo(basename);
}

Future<void> delete(String path) async {
  saf.DocumentFile? c = await traverse(path);


  if (!(c == null)) {
    await c.delete();
  }
}


Future<saf.DocumentFile?> traverse(String path) async
{
  Uri? root = selectedRoot;
  saf.DocumentFile? c;

  if(root==null)
    {
      return null;
    }

  if(path=='')
    {
      return await saf.fromTreeUri(root);
    }
  var pl = path.split("/");

  saf.DocumentFile? y;

  bool first = true;

  for (var i in pl) {
    if (i == '') {
      continue;
    }
    if (root == null) {
      return null;
    }

    if(first) {
      y = await saf.child(root, i);
      first=false;
    }
    else
      {
        if(c==null)
          {
            return null;
          }
        y= await c.child(i);
      }

    if (y == null) {
      return null;
    }

    root = y.uri;
    c = y;
  }
  return c;

}

Future<bool> exists(String path) async {
  saf.DocumentFile? c = await traverse(path);

  if (!(c == null)) {
    return true;
  }

  return false;
}

Future<void> rename(String path, String newbasename) async {
  saf.DocumentFile? c = await traverse(path);


  if (!(c == null)) {
    await c.renameTo(newbasename);
  }
}

Future<String> read(fn) async {
  saf.DocumentFile? c = await traverse(fn);


  if (!(c == null)) {
    var st = await saf.getDocumentContentAsString(c.uri);
    if (st == null) {
      throw Future.error(Error);
    }
    return st;
  }

  throw Future.error(Error);
}

Stream<String> ls(String fn, bool directories) async* {
  saf.DocumentFile? c = await traverse(fn);


  if (c == null) {
    return;
  }


  var l = await saf.listFiles(c.uri, columns: [
    saf.DocumentFileColumn.id,
    saf.DocumentFileColumn.displayName,
    saf.DocumentFileColumn.mimeType,
  ]).toList();

  for (var i in l) {
    if (directories) {
      if (!(i.metadata?.isDirectory ?? false)) {
        //isDirectory not working?
        if (!(i.data?[saf.DocumentFileColumn.mimeType] ==
            'vnd.android.document/directory')) {
          continue;
        }
      }
    } else {
      if ((i.metadata?.isDirectory ?? false)) {
        continue;
      }
    }

    String? x = i.data?[saf.DocumentFileColumn.displayName];

    if (!(x == null)) {
      yield x;
    }
  }
}
