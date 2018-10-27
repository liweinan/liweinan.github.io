---
title: 从postgres导出json数据，然后用spark来处理。
abstract: 可以从postgresql中select出所需要的数据，转成txt文件，然后把文件内容读取进spark。
---

## {{ page.title }}

可以从postgresql中select出所需要的数据，转成txt文件，然后把文件内容读取进spark。

```sql
sql> copy (select info from items) to '/tmp/foo.json';
```

```bash
$ spark-shell
```

```scala
scala> val df = spark.read.json("/tmp/foo.json")
df: org.apache.spark.sql.DataFrame = [distinct_id: string, event: string ... 3 more fields]
```

```txt
scala> df.printSchema()
root
 |-- distinct_id: string (nullable = true)
 |-- event: string (nullable = true)
 |-- ip: long (nullable = true)
 |-- properties: struct (nullable = true)
 |    |-- $browser: string (nullable = true)
 |    |-- $browser_version: double (nullable = true)
 |    |-- $ce_version: long (nullable = true)
 |    |-- $current_url: string (nullable = true)
 |    |-- $device: string (nullable = true)
 |    |-- $el_attr__href: boolean (nullable = true)
 |    |-- $el_text: string (nullable = true)
 |    |-- $elements: array (nullable = true)
 |    |    |-- element: struct (containsNull = true)
 |    |    |    |-- attr__aria-disabled: string (nullable = true)
 |    |    |    |-- attr__aria-selected: string (nullable = true)
 |    |    |    |-- attr__class: string (nullable = true)
 |    |    |    |-- attr__id: string (nullable = true)
 |    |    |    |-- attr__role: string (nullable = true)
 |    |    |    |-- attr__style: string (nullable = true)
 |    |    |    |-- classes: array (nullable = true)
 |    |    |    |    |-- element: string (containsNull = true)
 |    |    |    |-- nth_child: long (nullable = true)
 |    |    |    |-- nth_of_type: long (nullable = true)
 |    |    |    |-- tag_name: string (nullable = true)
 |    |-- $event_type: string (nullable = true)
 |    |-- $host: string (nullable = true)
 |    |-- $initial_referrer: string (nullable = true)
 |    |-- $initial_referring_domain: string (nullable = true)
 |    |-- $lib: string (nullable = true)
 |    |-- $lib_version: string (nullable = true)
 |    |-- $os: string (nullable = true)
 |    |-- $pathname: string (nullable = true)
 |    |-- $screen_height: long (nullable = true)
 |    |-- $screen_width: long (nullable = true)
 |    |-- $title: string (nullable = true)
 |    |-- distinct_id: string (nullable = true)
 |    |-- yyks_browser: string (nullable = true)
 |    |-- yyks_page: string (nullable = true)
 |    |-- yyks_platform: string (nullable = true)
 |-- timestamp: long (nullable = true)
```

```scala
scala> df.count()
res9: Long = 29

scala>
```

- [sql - Save PL/pgSQL output from PostgreSQL to a CSV file - Stack Overflow](https://stackoverflow.com/questions/1517635/save-pl-pgsql-output-from-postgresql-to-a-csv-file)
- [Fast CSV and JSON Ingestion in PostgreSQL with COPY](https://info.crunchydata.com/blog/fast-csv-and-json-ingestion-in-postgresql-with-copy)
- [postgresql - Inserting valid json with copy into postgres table - Stack Overflow](https://stackoverflow.com/questions/24190039/inserting-valid-json-with-copy-into-postgres-table)
- [PostgreSQL: Documentation: 11: 9.15. JSON Functions and Operators](https://www.postgresql.org/docs/current/static/functions-json.html)
- [Create Quick JSON Data Dumps From PostgreSQL | Hashrocket](https://hashrocket.com/blog/posts/create-quick-json-data-dumps-from-postgresql)
- [Is PostgreSQL Your Next JSON Database? - Compose Articles](https://www.compose.com/articles/is-postgresql-your-next-json-database/)
- [Postgres JSON: Unleash the Power of Storing JSON in Postgres | Codeship | via @codeship](https://blog.codeship.com/unleash-the-power-of-storing-json-in-postgres/)