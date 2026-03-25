/*------------------------------------------------------------------------------
    Run all sql script required for the PL/SQL debug framework assignment.
*/------------------------------------------------------------------------------

@@drop_and_create_debug_log_table;

@@debug_log_pkg_spec_and_body;

@@create_proc_adjust_salaries_by_commision;
