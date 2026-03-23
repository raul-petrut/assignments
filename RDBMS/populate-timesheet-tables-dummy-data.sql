/*------------------------------------------------------------------------------
    TABLE POPULATION
*/------------------------------------------------------------------------------

/*
    Remove all table data for a fresh start.
    Using TRUNCATE for faster execution.
*/
TRUNCATE TABLE ts_timesheet_entries
    PURGE MATERIALIZED VIEW LOG
    DROP STORAGE;

TRUNCATE TABLE ts_timesheets
    PURGE MATERIALIZED VIEW LOG
    DROP STORAGE;

TRUNCATE TABLE ts_projects
    PURGE MATERIALIZED VIEW LOG
    DROP STORAGE;

/*
    Dummy projects
*/
INSERT INTO ts_projects (code, name, department_id, project_manager_id, start_date, end_date, status, metadata_json)
VALUES ('PRJ-001', 'ERP Implementation', 10, 100, DATE '2024-01-01', NULL, 'ACTIVE',
        JSON_OBJECT('client' VALUE 'Internal', 'priority' VALUE 'HIGH'));

INSERT INTO ts_projects (code, name, department_id, project_manager_id, start_date, end_date, status, metadata_json)
VALUES ('PRJ-002', 'Mobile App Development', 20, 101, DATE '2024-02-01', NULL, 'ACTIVE',
        JSON_OBJECT('client' VALUE 'External', 'platform' VALUE 'iOS/Android'));

INSERT INTO ts_projects (code, name, department_id, project_manager_id, start_date, end_date, status, metadata_json)
VALUES ('PRJ-003', 'Data Migration', 30, 102, DATE '2023-10-01', DATE '2024-03-01', 'CLOSED',
        JSON_OBJECT('type' VALUE 'ETL', 'complexity' VALUE 'MEDIUM'));

INSERT INTO ts_projects (code, name, department_id, project_manager_id, start_date, status)
VALUES ('PRJ-004', 'Cloud Optimization', 10, 100, DATE '2024-05-01', 'PLANNED');


/*
    Dummy timesheets
*/

/* Employee 100 - Approved */
INSERT INTO ts_timesheets (employee_id, approver_id, week_start_date, week_end_date, status, submitted_at, approved_at)
VALUES (100, 101, DATE '2026-06-03', DATE '2026-06-09', 'APPROVED',
        DATE '2026-06-10', DATE '2026-06-11');

/* Employee 101 - Submitted */
INSERT INTO ts_timesheets (employee_id, approver_id, week_start_date, week_end_date, status, submitted_at)
VALUES (101, 102, DATE '2026-06-03', DATE '2026-06-09', 'SUBMITTED',
        DATE '2026-06-10');

/* Employee 102 - Draft */
INSERT INTO ts_timesheets (employee_id, approver_id, week_start_date, week_end_date, status)
VALUES (102, 100, DATE '2026-06-03', DATE '2026-06-09', 'DRAFT');

/* Employee 100 - Rejected */
INSERT INTO ts_timesheets (employee_id, approver_id, week_start_date, week_end_date, status, submitted_at, approved_at, rejection_reason)
VALUES (100, 101, DATE '2026-06-10', DATE '2026-06-16', 'REJECTED',
        DATE '2026-06-17', DATE '2026-06-18', 'Missing details');
        
/*
    Dummy timesheet entries
*/
        
/* Entries for Employee 100 - Approved Timesheet */
INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type, entry_note)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 100 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-001'),
    DATE '2026-06-03',
    8,
    'IN OFFICE',
    'Worked on ERP modules'
);

INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 100 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-002'),
    DATE '2026-06-04',
    6,
    'REMOTE'
);

INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 100 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-001'),
    DATE '2026-06-05',
    8,
    'IN OFFICE'
);

/* Entries for Employee 101 */
INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 101 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-002'),
    DATE '2026-06-03',
    7,
    'REMOTE'
);

/* Entry for leave */
INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type, entry_note)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 101 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-002'),
    DATE '2026-06-06',
    8,
    'LEAVE',
    'Annual leave'
);

/* Draft timesheet entry */
INSERT INTO ts_timesheet_entries (timesheet_id, project_id, work_date, hours_worked, work_type)
VALUES (
    (SELECT id FROM ts_timesheets WHERE employee_id = 102 AND week_start_date = DATE '2026-06-03'),
    (SELECT id FROM ts_projects WHERE code = 'PRJ-004'),
    DATE '2026-06-03',
    5,
    'IN OFFICE'
);