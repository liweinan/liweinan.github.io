# The Effect Of Connection.setAutoCommit(...) method in JDBC

I want to check how does the `setAutoCommit(...)` method defined in `java.sql.Connection` interface works. So I'll use the PostgreSQL JDBC driver to write an example to execute some SQL commands, and then to check how does the driver implments the JDBC interface.



I need to open the SQL logging capability of the PostgreSQL. I installed the `postgresql` package with Homebrew on my MacOS machine, and the configuration file to edit is `/usr/local/pgsql/data/postgresql.conf`. Here is what I have changed in configuration file:

```diff
--- postgresql.conf.orig	2017-05-03 23:23:53.000000000 +0800
+++ postgresql.conf	2017-05-03 23:11:48.000000000 +0800
@@ -333,18 +333,22 @@
 					# depending on platform.  csvlog
 					# requires logging_collector to be on.
 
+log_destination = stderr
+
 # This is used when logging to stderr:
 #logging_collector = off		# Enable capturing of stderr and csvlog
 					# into log files. Required to be on for
 					# csvlogs.
 					# (change requires restart)
 
+logging_collector = on
+
 # These are only used if logging_collector is on:
-#log_directory = 'pg_log'		# directory where log files are written,
+log_directory = 'pg_log'		# directory where log files are written,
 					# can be absolute or relative to PGDATA
-#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern,
+log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern,
 					# can include strftime() escapes
-#log_file_mode = 0600			# creation mode for log files,
+log_file_mode = 0600			# creation mode for log files,
 					# begin with 0 to use octal notation
 #log_truncate_on_rotation = off		# If on, an existing log file with the
 					# same name as the new log file will be
@@ -354,9 +358,9 @@
 					# or size-driven rotation.  Default is
 					# off, meaning append to existing files
 					# in all cases.
-#log_rotation_age = 1d			# Automatic rotation of logfiles will
+log_rotation_age = 1d			# Automatic rotation of logfiles will
 					# happen after that time.  0 disables.
-#log_rotation_size = 10MB		# Automatic rotation of logfiles will
+log_rotation_size = 10MB		# Automatic rotation of logfiles will
 					# happen after that much log output.
 					# 0 disables.
 
@@ -451,6 +455,7 @@
 					# e.g. '<%u%%%d> '
 #log_lock_waits = off			# log lock waits >= deadlock_timeout
 #log_statement = 'none'			# none, ddl, mod, all
+log_statement = 'all'
 #log_replication_commands = off
 #log_temp_files = -1			# log temporary files equal or larger
 					# than the specified size in kilobytes;
```

With the above changes, the postgresql server will log the SQL statements exectued from client requests.

---

The `autoCommit` property will be used to set `flags` in `executeInternal(..., int flags)` method of `org.postgresql.jdbc.PgStatement` class. Here is the relative code in the method:

```java
if (connection.getAutoCommit()) {
  flags |= QueryExecutor.QUERY_SUPPRESS_BEGIN;
}
```

From above code we can see the `QueryExecutor.QUERY_SUPPRESS_BEGIN` value is added into `flags`. Here is the definition of `QUERY_SUPPRESS_BEGIN` in `org.postgresql.core.QueryExecutor.QUERY_SUPPRESS_BEGIN` class:

```
  /**
   * Flag for query execution that indicates the automatic BEGIN on the first statement when outside
   * a transaction should not be done.
   */
  int QUERY_SUPPRESS_BEGIN = 16;
```

After the `flags` is set, it will finally affect the `sendQueryPreamble(...)` method in `org.postgresql.core.v3.QueryExecutorImpl` class. Here is the code of the method:

```java
 private ResultHandler sendQueryPreamble(final ResultHandler delegateHandler, int flags)
      throws IOException {
    // First, send CloseStatements for finalized SimpleQueries that had statement names assigned.
    processDeadParsedQueries();
    processDeadPortals();

    // Send BEGIN on first statement in transaction.
    if ((flags & QueryExecutor.QUERY_SUPPRESS_BEGIN) != 0
        || getTransactionState() != TransactionState.IDLE) {
      return delegateHandler;
    }

    int beginFlags = QueryExecutor.QUERY_NO_METADATA;
    if ((flags & QueryExecutor.QUERY_ONESHOT) != 0) {
      beginFlags |= QueryExecutor.QUERY_ONESHOT;
    }

    beginFlags |= QueryExecutor.QUERY_EXECUTE_AS_SIMPLE;

    beginFlags = updateQueryMode(beginFlags);

    sendOneQuery(beginTransactionQuery, SimpleQuery.NO_PARAMETERS, 0, 0, beginFlags);

    // Insert a handler that intercepts the BEGIN.
    return new ResultHandlerDelegate(delegateHandler) {
      private boolean sawBegin = false;

      public void handleResultRows(Query fromQuery, Field[] fields, List<byte[][]> tuples,
          ResultCursor cursor) {
        if (sawBegin) {
          super.handleResultRows(fromQuery, fields, tuples, cursor);
        }
      }

      public void handleCommandStatus(String status, int updateCount, long insertOID) {
        if (!sawBegin) {
          sawBegin = true;
          if (!status.equals("BEGIN")) {
            handleError(new PSQLException(GT.tr("Expected command status BEGIN, got {0}.", status),
                PSQLState.PROTOCOL_VIOLATION));
          }
        } else {
          super.handleCommandStatus(status, updateCount, insertOID);
        }
      }
    };
  }
```

In above code, if `QueryExecutor.QUERY_SUPPRESS_BEGIN`  is set in flag, then it will return immediately. The relative code is here:

```java
// Send BEGIN on first statement in transaction.
if ((flags & QueryExecutor.QUERY_SUPPRESS_BEGIN) != 0
    || getTransactionState() != TransactionState.IDLE) {
  return delegateHandler;
}
```

The `QueryExecutor.QUERY_SUPPRESS_BEGIN` is set by default, unless `autoCommit` is set to `false` in `java.sql.Connection`. If `QueryExecutor.QUERY_SUPPRESS_BEGIN` is unset, which means `autoCommit` is set to `false` in `java.sql.Connection` by the user, then the rest part of the code in `sendQueryPreamble(...)` method will be executed, and a `BEGIN` command will be sent to database server. Here is the relative code:

```java
sendOneQuery(beginTransactionQuery, SimpleQuery.NO_PARAMETERS, 0, 0, beginFlags);
```

The above code will send a `beginTransactionQuery` to the database server. We can see the definition of `beginTransactionQuery` in `org.postgresql.core.v3.QueryExecutorImpl` itself. Here is the definition:

```java
private final SimpleQuery beginTransactionQuery =
      new SimpleQuery(
          new NativeQuery("BEGIN", new int[0], false, SqlCommand.BLANK),
          null, false);
```

From the above definition we can see the `beginTransactionQuery` represents the `BEGIN` command in database server.