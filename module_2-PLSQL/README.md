# PL/SQL assignment: debug framework

Must be run inside Oracle HR schema.

Contents:  
    - `drop_and_create_debug_log_table.sql`: drop all tables to allow for a fresh start  
    - `debug_log_pkg_spec_and_body.sql`: create the debug package specifications and body  
    - `create_proc_adjust_salaries_by_commision.sql`: add dummy data to timesheet tables for the select queries  
    - `debug_framework_master.sql`: helper script that runs all the SQL queries  

Running `timesheets-master.sql` will run the following scripts in order:  
    - `drop_and_create_debug_log_table.sql`  
    - `debug_log_pkg_spec_and_body.sql`  
    - `create_proc_adjust_salaries_by_commision.sql`  
 
