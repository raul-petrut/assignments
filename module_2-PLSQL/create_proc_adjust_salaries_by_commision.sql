/*
    For all employees increase salary by "commision_pct".
    If NULL increase by 2% of current value.
    
    Only employees in sales department eligible for commission percentage.
*/
CREATE OR REPLACE PROCEDURE adjust_salaries_by_commision AS
    CURSOR c_employees IS
        SELECT
            employee_id,
            first_name,
            last_name,
            salary,
            commission_pct
        FROM employees emp INNER JOIN departments dep
        ON emp.department_id = dep.department_id
        WHERE UPPER(dep.department_name) = 'SALES'
        FOR UPDATE OF salary;

    l_old_salary   employees.salary%TYPE;
    l_new_salary   employees.salary%TYPE;
    l_increase_pct NUMBER(6,4);
BEGIN
    debug_utilitar.log_msg('Starting procedure adjust_salaries_by_commision');

    FOR employee IN c_employees LOOP
        l_old_salary := employee.salary;
        l_increase_pct := NVL(employee.commission_pct, 0.02);
        l_new_salary := l_old_salary + (l_old_salary * l_increase_pct);

        debug_utilitar.log_msg('Reading employee with ID = ' || employee.employee_id);
        debug_utilitar.log_var('employee_name', employee.first_name || ' ' || employee.last_name);
        debug_utilitar.log_var('old_salary', TO_CHAR(l_old_salary));
        debug_utilitar.log_var('commission_pct_used', TO_CHAR(l_increase_pct));
        debug_utilitar.log_var('new_salary_calculated', TO_CHAR(l_new_salary));

        UPDATE employees
           SET salary = l_new_salary
        WHERE CURRENT OF c_employees;

        debug_utilitar.log_msg('Updated salary for employee ID = ' || employee.employee_id);
    END LOOP;

    COMMIT;
    debug_utilitar.log_msg('Procedure adjust_salaries_by_commision finished successfully');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        debug_utilitar.log_err(
            'ADJUST_SALARIES_BY_COMMISION',
            SQLERRM
        );
        RAISE;
END adjust_salaries_by_commision;
/
