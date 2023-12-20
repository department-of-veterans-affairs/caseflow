
This directory contains SQL queries to be validated by running:
```
> bundle exec rake 'sql:validate[ reports/sql_queries, reports/queries_output]'
```
which runs queries specified in the `reports/sql_queries/*.sql` files and
saves the output to `reports/queries_output` for comparison and diagnostics.

For Rake tasks, arguments are passed in using brackets -- see [How To Use Arguments In a Rake Task](https://thoughtbot.com/blog/how-to-use-arguments-in-a-rake-task).

## Quickstart

To download and validate the most recent cards (a.k.a. queries and questions) 
from Metabase, run:
```
> scripts/metabase_client.sh downloadAndValidate
```

This will save Metabase query results in `reports/queries_output` and
compare those against results from running the extracted Rails query on 
the database in your current environment.

## Details

See code comments in `lib/tasks/sql.rake` for more detail.
RSpec file `spec/lib/tasks/sql_spec.rb` also validates all the queries in this
directory against data in the `test` database. This ensures the *.sql files
are syntactically ready for use in query result validation.

Files with the format `db<database_id>_c<card_id>.sql` were created by:
```
> bundle exec rake 'sql:extract_queries_from[ cards.json, reports/sql_queries]'
```

which extracts SQL queries from `cards.json`, which was created by running:
```
> scripts/metabase_client.sh cards cards.json
```

which uses Metabase's API to retrieve the SQL queries in Metabase.

To see the query in Metabase, use the `card_id` and browse to:
https://query.prod.appeals.va.gov/question/<card_id>

## Validating an SQL query

To include a new SQL query for validation, add the incantations below in
SQL comments.  See `sql_spec.rb` and the other `*.sql` files for examples.

- `RAILS_EQUIV`: identifies Rails code that is equivalent to the SQL query.
  If `array_output` appears in the query, the validator will automatically
  map the array into separate lines in the output file so that it will match 
  the output from the executing the SQL query.
- `POSTPROC_SQL_RESULT` (optional): identifies Rails code to postprocess SQL
  query results
- `SQL_DB_CONNECTION` (optional): identifies the class on which to call
  `.connection` to execute the SQL query. The default is `ActiveRecord::Base`.
  To run the SQL against VACOLS, use `VACOLS::Record` or the like.

They should be added directly to the query in Metabase (for later retrieval by
`metabase_client.sh`).  Before doing so, you can test the incantations locally
-- see next section.

## Testing your validation incantations

To test the incantations locally as you develop them:

1. Create a file, such as `for_testing.sql` in `reports/sql_queries`.
2. Add the incantations mentioned above.
3. Run `bundle exec rake 'sql:validate[ reports/sql_queries, reports/queries_output]'`
   and check the console output and `reports/queries_output/for_testing.*.out`.
   The output files must match exactly.

To validate your `sql` file individually, run:
```
> bundle exec rake 'sql:validate_file[ reports/sql_queries/for_testing.sql, tmp]'
```
and check the output in the `tmp` subdirectory.
