---
title: Enable the PostgreSQL SQL log output in MacOS 
---

First install `postgresql` with `brew`:

```bash
$ brew install postgresql
```

Then initialize the database:

```bash
$ initdb --locale=C -E UTF-8 /opt/homebrew/var/postgresql@14
```

Then edit configuration file `postgresql.conf`:

```bash
/opt/homebrew/var/postgresql@14/postgresql.conf
```

Add the following lines into the configuration file:

```properties
logging_collector = on
log_directory =  '/opt/homebrew/var/postgresql@14/logs'
log_statement = 'all'
```

Here is the screenshot of the configuration file:

![](https://raw.githubusercontent.com/liweinan/blogpics2025/main/0117/01.png)

Start/Restart the PostgreSQL server:

```bash
❯ pg_ctl -D /opt/homebrew/var/postgresql@14 restart
waiting for server to shut down.... done
server stopped
waiting for server to start....2025-01-15 13:29:13.189 CST [5565] LOG:  redirecting log output to logging collector process
2025-01-15 13:29:13.189 CST [5565] HINT:  Future log output will appear in directory "/opt/homebrew/var/postgresql@14/logs".                  done
server started
```

Run some examples that will cause SQL operations and look at the generated logs:

```bash
❯ tail /opt/homebrew/var/postgresql@14/logs/postgresql-2025-01-13_000000.log                                                                                                                                         22:53:17
2025-01-13 23:52:15.882 CST [9665] LOG:  execute <unnamed>: UPDATE STEP_EXECUTION SET ENDTIME=$1, BATCHSTATUS=$2, EXITSTATUS=$3, EXECUTIONEXCEPTION=$4, PERSISTENTUSERDATA=$5, READCOUNT=$6, WRITECOUNT=$7, COMMITCOUNT=$8, ROLLBACKCOUNT=$9, READSKIPCOUNT=$10, PROCESSSKIPCOUNT=$11, FILTERCOUNT=$12, WRITESKIPCOUNT=$13, READERCHECKPOINTINFO=$14, WRITERCHECKPOINTINFO=$15 WHERE STEPEXECUTIONID=$16
2025-01-13 23:52:15.882 CST [9665] DETAIL:  parameters: $1 = '2025-01-13 23:52:15.875+08', $2 = 'COMPLETED', $3 = 'prepurge process', $4 = NULL, $5 = NULL, $6 = '0', $7 = '0', $8 = '0', $9 = '0', $10 = '0', $11 = '0', $12 = '0', $13 = '0', $14 = NULL, $15 = NULL, $16 = '19'
2025-01-13 23:52:15.890 CST [9666] LOG:  execute <unnamed>: UPDATE STEP_EXECUTION SET ENDTIME=$1, BATCHSTATUS=$2, EXITSTATUS=$3, EXECUTIONEXCEPTION=$4, PERSISTENTUSERDATA=$5, READCOUNT=$6, WRITECOUNT=$7, COMMITCOUNT=$8, ROLLBACKCOUNT=$9, READSKIPCOUNT=$10, PROCESSSKIPCOUNT=$11, FILTERCOUNT=$12, WRITESKIPCOUNT=$13, READERCHECKPOINTINFO=$14, WRITERCHECKPOINTINFO=$15 WHERE STEPEXECUTIONID=$16
2025-01-13 23:52:15.890 CST [9666] DETAIL:  parameters: $1 = '2025-01-13 23:52:15.875+08', $2 = 'COMPLETED', $3 = 'prepurge process', $4 = NULL, $5 = NULL, $6 = '0', $7 = '0', $8 = '0', $9 = '0', $10 = '0', $11 = '0', $12 = '0', $13 = '0', $14 = NULL, $15 = NULL, $16 = '19'
2025-01-13 23:52:15.898 CST [9667] LOG:  execute <unnamed>: UPDATE JOB_EXECUTION SET ENDTIME=$1, LASTUPDATEDTIME=$2, BATCHSTATUS=$3, EXITSTATUS=$4, RESTARTPOSITION=$5 WHERE JOBEXECUTIONID=$6
2025-01-13 23:52:15.898 CST [9667] DETAIL:  parameters: $1 = '2025-01-13 23:52:15.891+08', $2 = '2025-01-13 23:52:15.891+08', $3 = 'COMPLETED', $4 = 'COMPLETED', $5 = NULL, $6 = '19'
2025-01-13 23:52:15.907 CST [9668] LOG:  execute <unnamed>: SELECT JOB_EXECUTION.JOBEXECUTIONID FROM JOB_EXECUTION INNER JOIN JOB_INSTANCE ON JOB_EXECUTION.JOBINSTANCEID=JOB_INSTANCE.JOBINSTANCEID WHERE JOB_EXECUTION.BATCHSTATUS IN ('STARTED', 'STARTING') AND JOB_INSTANCE.JOBNAME=$1
2025-01-13 23:52:15.907 CST [9668] DETAIL:  parameters: $1 = 'prepurge'
2025-01-13 23:52:15.914 CST [9669] LOG:  execute <unnamed>: SELECT * FROM JOB_EXECUTION WHERE lastupdatedtime < $1 AND batchstatus in ('STOPPING', 'STARTED', 'STARTING')
2025-01-13 23:52:15.914 CST [9669] DETAIL:  parameters: $1 = '2025-01-13 23:52:15.91293+08'
```

The SQL log are recorded in the log file.

