/*------------------------------------------------------------------------------
    VIEW CREATION
*/------------------------------------------------------------------------------

/*
    TODO: description
*/
CREATE OR REPLACE VIEW vw_ts_entry_details AS
SELECT
    te.id                                          AS timesheet_entry_id,
    te.timesheet_id,
    tt.week_start_date,
    tt.week_end_date,
    tt.status                                        AS timesheet_status,
    tt.submitted_at,
    tt.approved_at,
    e.employee_id,
    e.first_name || ' ' || e.last_name              AS employee_full_name,
    e.email,
    e.job_id,
    j.job_title,
    e.manager_id,
    mgr.first_name || ' ' || mgr.last_name           AS manager_full_name,
    e.department_id                                  AS employee_department_id,
    ed.department_name                               AS employee_department_name,
    l.location_id,
    l.city,
    l.state_province,
    c.country_id,
    c.country_name,
    r.region_id,
    r.region_name,
    p.id                                            AS project_id,
    p.code,
    p.name,
    p.status,
    p.department_id                                  AS project_department_id,
    pd.department_name                               AS project_department_name,
    p.project_manager_id,
    te.work_date,
    te.hours_worked,
    te.work_type,
    te.entry_note,
    p.metadata_json
FROM ts_timesheet_entries te
JOIN ts_timesheets tt
    ON tt.id = te.timesheet_id
JOIN employees e
    ON e.employee_id = tt.employee_id
LEFT JOIN employees mgr
    ON mgr.employee_id = e.manager_id
LEFT JOIN jobs j
    ON j.job_id = e.job_id
LEFT JOIN departments ed
    ON ed.department_id = e.department_id
LEFT JOIN locations l
    ON l.location_id = ed.location_id
LEFT JOIN countries c
    ON c.country_id = l.country_id
LEFT JOIN regions r
    ON r.region_id = c.region_id
JOIN ts_projects p
    ON p.id = te.project_id
LEFT JOIN departments pd
    ON pd.department_id = p.department_id;


/*
    TODO: description
*/
CREATE MATERIALIZED VIEW mv_ts_dept_monthly_hours
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    e.department_id                                  AS employee_department_id,
    d.department_name,
    TRUNC(te.work_date, 'MM')                        AS work_month,
    COUNT(DISTINCT tt.id)                            AS timesheet_count,
    COUNT(DISTINCT tt.employee_id)                   AS employee_count,
    COUNT(te.id)                                     AS entry_count,
    SUM(te.hours_worked)                             AS total_hours
FROM ts_timesheet_entries te
JOIN ts_timesheets tt
    ON tt.id = te.timesheet_id
JOIN employees e
    ON e.employee_id = tt.employee_id
LEFT JOIN departments d
    ON d.department_id = e.department_id
WHERE tt.status = 'APPROVED'
GROUP BY
    e.department_id,
    d.department_name,
    TRUNC(te.work_date, 'MM');