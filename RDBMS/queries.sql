/*------------------------------------------------------------------------------
    Required queries
*/------------------------------------------------------------------------------

/*
    Show the total hours worked in a month by department.
*/
SELECT
    dep.department_id,
    dep.department_name,
    TRUNC(te.work_date, 'MM') AS work_month,
    SUM(te.hours_worked)      AS total_approved_hours
    
FROM ts_timesheet_entries te
JOIN ts_timesheets tt
    ON tt.id = te.timesheet_id
JOIN employees emp
    ON emp.employee_id = tt.employee_id
JOIN departments dep
    ON dep.department_id = emp.department_id

WHERE tt.status = 'APPROVED'

GROUP BY
    dep.department_id,
    dep.department_name,
    TRUNC(te.work_date, 'MM')
ORDER BY
    work_month,
    dep.department_id;


/*
   Show all employees and whether they have a timesheet for a selected week.
*/
SELECT
    emp.employee_id,
    emp.first_name,
    emp.last_name,
    emp.email,
    dep.department_name,
    tt.id              AS timesheet_id,
    tt.week_start_date,
    tt.week_end_date,
    tt.status          AS timesheet_status,
    tt.submitted_at,
    tt.approved_at
FROM employees emp
LEFT JOIN departments dep
    ON dep.department_id = emp.department_id
LEFT JOIN ts_timesheets tt
    ON tt.employee_id = emp.employee_id
   AND tt.week_start_date = DATE '2024-06-03'
ORDER BY
    emp.employee_id;


/*
   Rank employees within each department and month by total approved hours,
   using DENSE_RANK().
*/
WITH employee_monthly_hours AS (
    SELECT
        dep.department_id,
        dep.department_name,
        emp.employee_id,
        emp.first_name || ' ' || emp.last_name AS employee_full_name,
        TRUNC(te.work_date, 'MM')          AS work_month,
        SUM(te.hours_worked)               AS total_approved_hours
    FROM ts_timesheet_entries te
    JOIN ts_timesheets tt
        ON tt.id = te.timesheet_id
    JOIN employees emp
        ON emp.employee_id = tt.employee_id
    JOIN departments dep
        ON dep.department_id = emp.department_id
    WHERE tt.status = 'APPROVED'
    GROUP BY
        dep.department_id,
        dep.department_name,
        emp.employee_id,
        emp.first_name || ' ' || emp.last_name,
        TRUNC(te.work_date, 'MM')
)
SELECT
    department_id,
    department_name,
    work_month,
    employee_id,
    employee_full_name,
    total_approved_hours,
    DENSE_RANK() OVER (
        PARTITION BY department_id, work_month
        ORDER BY total_approved_hours DESC
    ) AS dept_month_rank
FROM employee_monthly_hours
ORDER BY
    work_month,
    department_id,
    dept_month_rank,
    employee_id;
