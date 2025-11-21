{* Name: user_activity_loader.4gl
 * Purpose: Data loading module for User Activity Analyzer
 * Context: Following IDU/data module patterns from knowledge_base.JSON
 * Style: snake_case, 2-space indentation per project standards
 * SQL: UPPERCASE keywords, parameterized queries per sql_best_practices.json
 *}

IMPORT FGL user_activity_constants
IMPORT FGL user_activity_util

SCHEMA records

-- User activity record structure
-- Pattern: Following RECORD LIKE table.* pattern from knowledge_base.JSON
PUBLIC TYPE t_user_activity RECORD
  user_id INTEGER,
  last_login DATETIME YEAR TO SECOND,
  days_since_login INTEGER,
  category STRING
END RECORD

{* Function: load_user_ids
 * Purpose: Load list of user IDs from database
 * Pattern: Based on eper_data_class.4gl query patterns
 * SQL: SELECT with explicit columns, parameterized queries
 * Returns: Array of user IDs, or empty array on error
 *}
PUBLIC FUNCTION load_user_ids() 
  RETURNS DYNAMIC ARRAY OF INTEGER
  DEFINE l_user_ids DYNAMIC ARRAY OF INTEGER
  DEFINE l_user_id INTEGER
  DEFINE l_idx INTEGER
  DEFINE l_sql STRING
  
  -- Initialize array
  CALL l_user_ids.clear()
  LET l_idx = 1
  
  -- Build SQL query per sql_best_practices.json formatting
  -- SQL keywords UPPERCASE, table/column names lowercase
  LET l_sql = "SELECT user_id ",
              "FROM ", user_activity_constants.C_TABLE_USERS, " ",
              "WHERE active = ? ",
              "ORDER BY user_id"
  
  -- Set error handling per sql_best_practices.json
  WHENEVER ERROR RAISE
  
  -- Execute query with prepared statement pattern
  DECLARE user_id_cursor CURSOR FROM l_sql
  
  -- Bind parameter and iterate results
  FOREACH user_id_cursor USING "Y" INTO l_user_id
    IF user_activity_util.validate_user_id(l_user_id) THEN
      LET l_user_ids[l_idx] = l_user_id
      LET l_idx = l_idx + 1
    END IF
  END FOREACH
  
  WHENEVER ERROR STOP
  
  RETURN l_user_ids
END FUNCTION

{* Function: load_user_last_login
 * Purpose: Load user's last login timestamp from database
 * Pattern: Based on single-row SELECT pattern from sql_best_practices.json
 * Args: p_user_id - user ID to look up
 * Returns: Last login timestamp, or NULL if not found
 *}
PUBLIC FUNCTION load_user_last_login(p_user_id INTEGER) 
  RETURNS DATETIME YEAR TO SECOND
  DEFINE l_last_login DATETIME YEAR TO SECOND
  DEFINE l_sql STRING
  
  -- Build SQL with MAX aggregation for last login
  -- Following sql_best_practices.json SELECT patterns
  LET l_sql = "SELECT MAX(login_timestamp) ",
              "FROM ", user_activity_constants.C_TABLE_USER_LOGINS, " ",
              "WHERE user_id = ?"
  
  -- Error handling per sql_best_practices.json
  WHENEVER ERROR RAISE
  
  -- Single-row SELECT...INTO pattern
  PREPARE login_stmt FROM l_sql
  EXECUTE login_stmt USING p_user_id INTO l_last_login
  
  -- Check status immediately after SQL operation per Genero best practice
  IF status != 0 THEN
    LET l_last_login = NULL
  END IF
  
  WHENEVER ERROR STOP
  
  RETURN l_last_login
END FUNCTION

{* Function: load_all_user_activity
 * Purpose: Load complete user activity data for analysis
 * Pattern: Combines load functions following project composition patterns
 * Returns: Dynamic array of user activity records
 *}
PUBLIC FUNCTION load_all_user_activity() 
  RETURNS DYNAMIC ARRAY OF t_user_activity
  DEFINE l_activities DYNAMIC ARRAY OF t_user_activity
  DEFINE l_user_ids DYNAMIC ARRAY OF INTEGER
  DEFINE l_idx INTEGER
  DEFINE l_user_id INTEGER
  DEFINE l_last_login DATETIME YEAR TO SECOND
  DEFINE l_days_since INTEGER
  
  -- Initialize results
  CALL l_activities.clear()
  
  -- Load all user IDs
  LET l_user_ids = load_user_ids()
  
  -- Process each user
  FOR l_idx = 1 TO l_user_ids.getLength()
    LET l_user_id = l_user_ids[l_idx]
    
    -- Load last login for this user
    LET l_last_login = load_user_last_login(l_user_id)
    
    -- Calculate days since login
    LET l_days_since = user_activity_util.calculate_days_since_login(l_last_login)
    
    -- Build activity record
    LET l_activities[l_idx].user_id = l_user_id
    LET l_activities[l_idx].last_login = l_last_login
    LET l_activities[l_idx].days_since_login = l_days_since
    LET l_activities[l_idx].category = user_activity_util.categorize_user_by_activity(l_days_since)
  END FOR
  
  RETURN l_activities
END FUNCTION
