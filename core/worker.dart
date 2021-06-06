import 'route.dart';

import './router.dart';
import '../controller/indexController.dart';
import 'serverRequest.dart';
import 'serverException.dart';
import 'serverResponse.dart';

class Worker {
  Router router = Router();

  init() async {
    await router.initDB();

    router.addBeforeWare((ServerRequest req, ServerResponse res) async {
      // throw ServerException("Auth fail", code:200);
    });

    router.get('/', IndexController.index, useDB: false);

    router.get('/file', IndexController.file, useDB: false);

    router.get('/listDocs', IndexController.listDocs);

    router.post('/post', IndexController.post);
  }
}
