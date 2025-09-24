class Db {
  static const suportDD = ['postgres'];

  final String host;
  final int port;
  final String db;
  final String table;
  final String user;
  final String password;
  final bool unixSocket;
  final bool ssl;

  Db(
    this.host,
    this.port,
    this.db,
    this.table,
    this.user,
    this.password,
    this.unixSocket,
    this.ssl,
  );

  factory Db.fromString(String conString) {
    final pars = Uri.parse(conString);
    if (!suportDD.contains(pars.scheme)) {
      throw Exception('database: ${pars.scheme} not suported');
    }
    final [user, password] = pars.userInfo.split(':');
    final params = pars.queryParameters;
    return Db(
      pars.host,
      pars.hasPort ? pars.port : 5432,
      pars.pathSegments.last,
      params['table'] ?? 'events',
      user,
      password,
      params['unix'] == 'true',
      params['ssl'] == 'true',
    );
  }
}
