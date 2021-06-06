class Route {
  String url = "";
  Function fn = () {};
  List<Function> beforeWare = [];
  List<Function> afterWare = [];
  bool useDB = true;

  Route(
      String u, Function f, List<Function> bw, List<Function> aw, bool ud) {
    url = u;
    fn = f;
    beforeWare = bw;
    afterWare = aw;
    this.useDB = ud;
  }
}
