CREATE OR REPLACE PACKAGE debug_utilitar
IS
    g_debug_mode BOOLEAN := FALSE;

    PROCEDURE enable_debug;
    PROCEDURE disable_debug;
    
    PROCEDURE log_msg(p_message VARCHAR2);
    PROCEDURE log_var(p_var_name VARCHAR2, p_value VARCHAR2);
    PROCEDURE log_err(p_proc_name VARCHAR2, p_error VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY debug_utilitar
IS

    l_debug_mode_disabled_exception EXCEPTION;

    /*
        Return depth of the most relevant subprogram that logs the error.
        At depth 1 we have the current subprogram "DEBUG_UTILITAR".
    */
    FUNCTION get_relevant_depth RETURN PLS_INTEGER IS
        l_name VARCHAR2(4000);
    BEGIN
        FOR i IN 2 .. UTL_CALL_STACK.dynamic_depth LOOP
            l_name := UPPER(NVL(
                UTL_CALL_STACK.concatenate_subprogram(UTL_CALL_STACK.subprogram(i)),
                ''
            ));
            
            -- we ignore the "DEBUG_UTILITAR" stack since it's not relevant
            IF l_name NOT LIKE 'DEBUG_UTILITAR%' THEN
                RETURN i;
            END IF;
        END LOOP;

        RETURN 2;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 2;
    END get_relevant_depth;

    /*
        Gets the name of the module that triggered the debug framework.
    */
    FUNCTION get_current_module_name RETURN VARCHAR2 IS
        l_depth  PLS_INTEGER;
        l_owner  VARCHAR2(128);
        l_unit   VARCHAR2(4000);
        l_module VARCHAR2(4000);
    BEGIN
        l_depth := get_relevant_depth;
        l_owner := UTL_CALL_STACK.owner(l_depth);
        l_unit  := UTL_CALL_STACK.concatenate_subprogram(UTL_CALL_STACK.subprogram(l_depth));

        IF l_unit IS NULL OR UPPER(l_unit) = '__ANONYMOUS_BLOCK' THEN
            l_module := NVL(SYS_CONTEXT('USERENV', 'MODULE'), 'ANONYMOUS_BLOCK');
        ELSE
            l_module := CASE
                            WHEN l_owner IS NOT NULL THEN l_owner || '.' || l_unit
                            ELSE l_unit
                        END;
        END IF;
    
        -- return only the first 100 chars since
        -- debug_log.module_name is defined as VARCHAR2(100)
        RETURN SUBSTR(l_module, 1, 100);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SUBSTR(NVL(SYS_CONTEXT('USERENV', 'MODULE'), 'UNKNOWN_MODULE'), 1, 100);
    END get_current_module_name;
    
    /*
        Gets the line number where the debug call was triggered
        inside the corresponding subprogram.
    */
    FUNCTION get_current_line_no RETURN NUMBER IS
        l_depth PLS_INTEGER;
    BEGIN
        l_depth := get_relevant_depth;
        RETURN UTL_CALL_STACK.unit_line(l_depth);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_current_line_no;
    
    /*
        Procedure that handles DML functionality for all debug logs
        to reduce code repetition.
        Defined as "AUTONOMOUS_TRANSACTION" to separate the debug
        transaction from the main transaction.
    */
    PROCEDURE write_log(
        p_message     IN VARCHAR2,
        p_module_name IN VARCHAR2 DEFAULT NULL,
        p_line_no     IN NUMBER   DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_module_name debug_log.module_name%TYPE;
        l_line_no     debug_log.line_no%TYPE;
        l_message     debug_log.log_message%TYPE;
    BEGIN
        IF NOT g_debug_mode THEN
            RAISE l_debug_mode_disabled_exception;
        END IF;

        l_module_name := SUBSTR(NVL(p_module_name, get_current_module_name), 1, 100);
        l_line_no     := NVL(p_line_no, get_current_line_no);
        l_message     := SUBSTR(NVL(p_message, 'NULL'), 1, 4000);

        INSERT INTO debug_log (
            module_name,
            line_no,
            log_message
        )
        VALUES (
            l_module_name,
            l_line_no,
            l_message
        );

        COMMIT;
    EXCEPTION
        WHEN l_debug_mode_disabled_exception THEN
            dbms_output.put_line('error: debug_mode must be enabled!');
        WHEN OTHERS THEN
            ROLLBACK;
    END write_log;

    PROCEDURE enable_debug IS
    BEGIN
        g_debug_mode := TRUE;
        write_log('[INFO] Debug mode enabled', 'DEBUG_UTILITAR.ENABLE_DEBUG', NULL);
    END enable_debug;
    
    PROCEDURE disable_debug IS
    BEGIN
        g_debug_mode := FALSE;
        write_log('[INFO] Debug mode disabled', 'DEBUG_UTILITAR.DISABLE_DEBUG', NULL);
    END disable_debug;
    
    PROCEDURE log_msg(p_message VARCHAR2) IS
    BEGIN
        write_log('[INFO] ' || p_message);
    END log_msg;
    
    PROCEDURE log_var(p_var_name VARCHAR2, p_value VARCHAR2) IS
    BEGIN
        write_log('[INFO] ' || NVL(p_var_name, 'UNKNOWN_VAR') || ' = ' || NVL(p_value, 'NULL'));
    END log_var;
    
    PROCEDURE log_err(p_proc_name VARCHAR2, p_error VARCHAR2) IS
    BEGIN
        write_log(
            '[ERROR] ' || NVL(p_error, 'Unknown error'),
            NVL(SUBSTR(p_proc_name, 1, 100), get_current_module_name),
            get_current_line_no
        );
    END log_err;
    
END;
/