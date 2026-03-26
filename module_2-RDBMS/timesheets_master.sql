/*------------------------------------------------------------------------------
    Run all sql script required for the timesheets assignment
*/------------------------------------------------------------------------------

@@purge-timesheet-tables;

@@create-timesheet-tables;

@@populate-timesheet-tables-dummy-data;

@@create-timesheet-views;