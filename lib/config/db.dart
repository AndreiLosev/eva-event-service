class Db {
  final String host;
  final int port;
  final String db;
  final String table;
  final String user;
  final String password;
  final bool unixSocket;

  Db(
    this.host,
    this.port,
    this.db,
    this.table,
    this.user,
    this.password,
    this.unixSocket,
  );

  factory Db.fromMap(Map map) {
    return Db(
      map['db_host'],
      map['db_port'],
      map['db_name'],
      map['db_table'],
      map['user'],
      map['password'],
      map['db_unix_socket'],
    );
  }
}
