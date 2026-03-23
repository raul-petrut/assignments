# RDBMS assignment: timesheet tables

Must be run inside Oracle HR schema.

Contents:
    - `purge-timesheet-tables.sql`: drop all tables to allow for a fresh start
    - `create-timesheet-tables.sql`: create all tables necessary
    - `populate-timesheet-tables-dummy-data.sql`: add dummy data to timesheet tables for the select queries
    - `create-timesheet-views.sql`: create views involving timesheet tables
    - `queries.sql`: run necessary queries specified in the assignment instructions
    - `timsheets-master.sql`: helper script that runs all the SQL queries (excluding `queries.sql`)

Running `timesheets-master.sql` will run the following scripts in order:
    - `purge-timesheet-tables.sql`
    - `create-timesheet-tables.sql`
    - `populate-timesheet-tables-dummy-data.sql`
    - `create-timesheet-views.sql`
