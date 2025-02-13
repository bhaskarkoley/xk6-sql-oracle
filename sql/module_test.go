package sql_test

import (
	_ "embed"
	"testing"

	"github.com/grafana/xk6-sql/sql"
	"github.com/grafana/xk6-sql/sqltest"
	_ "github.com/proullon/ramsql/driver"
)

//go:embed testdata/script.js
var script string

// TestIntegration performs an integration test creating a ramsql database.
func TestIntegration(t *testing.T) {
	t.Parallel()

	sql.RegisterModule("ramsql")

	sqltest.RunScript(t, "ramsql", "testdb", script)
}
