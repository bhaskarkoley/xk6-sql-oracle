import sql from 'k6/x/sql';

// The second argument is a Oracle connection string, e.g.
// `user="myuser" password="mypass" connectString="127.0.0.1:1521/mydb"`
const db = sql.open('oracle', ``);

export function teardown() {
  db.close();
}

export default function () {

  let results = sql.query(db, "SELECT * FROM dual");
  for (const row of results) {
    // Convert array of ASCII integers into strings. See https://github.com/grafana/xk6-sql/issues/12
    console.log(`bh`);
  }
}
