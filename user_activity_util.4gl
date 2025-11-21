{* Name: user_activity_util.4gl
 * Purpose: Helper functions for User Activity Analyzer
 * Context: Following patterns from knowledge_base.JSON (util files)
 * Style: snake_case naming, 2-space indentation, inline comments
 * SQL: Parameterized queries with ? and USING per sql_best_practices.json
 *}

IMPORT FGL user_activity_constants

SCHEMA records

{* Function: validate_user_id
 * Purpose: Validate input user ID data
 * Pattern: Based on ac_util.4gl validate_ac_data pattern
 * Args: p_user_id - user ID to validate
 * Returns: TRUE if valid, FALSE otherwise
 *}
PUBLIC FUNCTION validate_user_id(p_user_id INTEGER) RETURNS BOOLEAN
  DEFINE l_is_valid BOOLEAN
  
  LET l_is_valid = TRUE
  
  -- Validate user ID is positive
  IF p_user_id IS NULL OR p_user_id <= 0 THEN
    LET l_is_valid = FALSE
  END IF
  
  RETURN l_is_valid
END FUNCTION

{* Function: calculate_days_since_login
 * Purpose: Convert datetime to days difference from current date
 * Pattern: Inferred from project date handling needs
 * Args: p_last_login - last login timestamp
 * Returns: Number of days since last login, or -1 if NULL
 *}
PUBLIC FUNCTION calculate_days_since_login(p_last_login DATETIME YEAR TO SECOND) 
  RETURNS INTEGER
  DEFINE l_days_diff INTEGER
  DEFINE l_current_date DATETIME YEAR TO SECOND
  
  -- Handle NULL last login
  IF p_last_login IS NULL THEN
    RETURN -1
  END IF
  
  LET l_current_date = CURRENT
  
  -- Calculate difference in days
  LET l_days_diff = (l_current_date - p_last_login) / INTERVAL(1) DAY TO DAY
  
  RETURN l_days_diff
END FUNCTION

{* Function: categorize_user_by_activity
 * Purpose: Categorize a user based on last login days
 * Pattern: Based on project business logic requirements
 * Args: p_days_since_login - days since last login
 * Returns: Category string (ACTIVE/DORMANT/INACTIVE)
 * Rules:
 *   ACTIVE = logged in within last 7 days
 *   DORMANT = no login for 7-30 days
 *   INACTIVE = no login for 30+ days
 *}
PUBLIC FUNCTION categorize_user_by_activity(p_days_since_login INTEGER) 
  RETURNS STRING
  DEFINE l_category STRING
  
  -- Apply categorization rules per requirements
  CASE
    WHEN p_days_since_login < 0 THEN
      -- No login data available
      LET l_category = user_activity_constants.C_CATEGORY_INACTIVE
    WHEN p_days_since_login <= user_activity_constants.C_THRESHOLD_ACTIVE_DAYS THEN
      LET l_category = user_activity_constants.C_CATEGORY_ACTIVE
    WHEN p_days_since_login <= user_activity_constants.C_THRESHOLD_DORMANT_DAYS THEN
      LET l_category = user_activity_constants.C_CATEGORY_DORMANT
    OTHERWISE
      LET l_category = user_activity_constants.C_CATEGORY_INACTIVE
  END CASE
  
  RETURN l_category
END FUNCTION

{* Function: format_timestamp_for_log
 * Purpose: Format timestamp for logging purposes
 * Pattern: Inferred from project formatting needs
 * Args: p_timestamp - timestamp to format
 * Returns: Formatted string representation
 *}
PUBLIC FUNCTION format_timestamp_for_log(p_timestamp DATETIME YEAR TO SECOND) 
  RETURNS STRING
  DEFINE l_formatted STRING
  
  IF p_timestamp IS NULL THEN
    LET l_formatted = "NULL"
  ELSE
    LET l_formatted = p_timestamp
  END IF
  
  RETURN l_formatted
END FUNCTION
