/*
    Drop all timesheet tables along it's constraints in order of dependency.
    
    If error code is not '-942' (Table does not exists) then raise the exception.
    For materialized views we check for error code '-12003'
        (Materialized view does not exist).
*/

BEGIN
   EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ts_dept_monthly_hours';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -12003 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP VIEW vw_ts_entry_details';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ts_timesheet_entries CASCADE CONSTRAINTS PURGE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ts_timesheets CASCADE CONSTRAINTS PURGE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ts_projects CASCADE CONSTRAINTS PURGE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/