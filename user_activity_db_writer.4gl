{* Name: user_activity_db_writer.4gl
 * Purpose: Database writer module for logging inactive users
 * Context: Following IDU insert patterns from knowledge_base.JSON
 * Style: snake_case, 2-space indentation per project standards
 * SQL: UPPERCASE keywords, parameterized INSERT per sql_best_practices.json
 * Transactions: Using db_begin_work/db_commit_work per sql_best_practices.json
 *}

IMPORT FGL user_activity_constants
IMPORT FGL user_activity_loader
IMPORT FGL user_activity_util

SCHEMA records

{* Function: log_inactive_user
 * Purpose: Insert single inactive user record into log table
 * Pattern: Based on ac_data_idu.4gl insert_record pattern
 * Args: 
 *   p_user_id - user ID to log
 *   p_last_login - last login timestamp
 *   p_days_since - days since last login
 * Returns: C_ERR_SUCCESS on success, error code on failure
 * SQL: INSERT with VALUES pattern per sql_best_practices.json
 *}
PUBLIC FUNCTION log_inactive_user(
  p_user_id INTEGER,
  p_last_login DATETIME YEAR TO SECOND,
  p_days_since INTEGER
) RETURNS INTEGER
  DEFINE l_sql STRING
  DEFINE l_logged_at DATETIME YEAR TO SECOND
  DEFINE l_status INTEGER
  
  -- Get current timestamp for log entry
  LET l_logged_at = CURRENT
  
  -- Build INSERT statement per sql_best_practices.json
  -- SQL keywords UPPERCASE, table name lowercase
  LET l_sql = "INSERT INTO ", user_activity_constants.C_TABLE_INACTIVE_LOG, " ",
              "(user_id, last_login, days_since_login, logged_at) ",
              "VALUES (?, ?, ?, ?)"
  
  -- Error handling per sql_best_practices.json
  WHENEVER ERROR RAISE
  
  -- Execute parameterized INSERT with USING clause
  PREPARE insert_stmt FROM l_sql
  EXECUTE insert_stmt USING p_user_id, p_last_login, p_days_since, l_logged_at
  
  -- Check status per sql_best_practices.json
  LET l_status = status
  IF l_status != 0 THEN
    WHENEVER ERROR STOP
    RETURN user_activity_constants.C_ERR_DATABASE
  END IF
  
  WHENEVER ERROR STOP
  
  RETURN user_activity_constants.C_ERR_SUCCESS
END FUNCTION

{* Function: log_inactive_users_batch
 * Purpose: Write all inactive users to database log table
 * Pattern: Based on transaction patterns from sql_best_practices.json
 * Args: p_activities - array of user activity records
 * Returns: Number of records logged, or error code on failure
 * Transaction: Uses db_begin_work/db_commit_work pattern
 * Note: db_* functions assumed to exist based on sql_best_practices.json
 *}
PUBLIC FUNCTION log_inactive_users_batch(
  p_activities DYNAMIC ARRAY OF user_activity_loader.t_user_activity
) RETURNS INTEGER
  DEFINE l_idx INTEGER
  DEFINE l_logged_count INTEGER
  DEFINE l_result INTEGER
  DEFINE l_activity user_activity_loader.t_user_activity
  
  LET l_logged_count = 0
  
  -- Begin transaction per sql_best_practices.json
  -- Note: db_begin_work assumed from sql_best_practices.json patterns
  CALL db_begin_work()
  
  -- Error handling for transaction block
  WHENEVER ERROR RAISE
  
  -- Process each activity record
  FOR l_idx = 1 TO p_activities.getLength()
    LET l_activity = p_activities[l_idx]
    
    -- Only log INACTIVE users per requirements
    IF l_activity.category = user_activity_constants.C_CATEGORY_INACTIVE THEN
      LET l_result = log_inactive_user(
        l_activity.user_id,
        l_activity.last_login,
        l_activity.days_since_login
      )
      
      IF l_result = user_activity_constants.C_ERR_SUCCESS THEN
        LET l_logged_count = l_logged_count + 1
      ELSE
        -- Rollback on error per sql_best_practices.json
        CALL db_rollback_work()
        WHENEVER ERROR STOP
        RETURN user_activity_constants.C_ERR_DATABASE
      END IF
    END IF
  END FOR
  
  -- Commit transaction per sql_best_practices.json
  CALL db_commit_work()
  
  WHENEVER ERROR STOP
  
  RETURN l_logged_count
END FUNCTION
