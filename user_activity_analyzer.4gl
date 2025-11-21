{* Name: user_activity_analyzer.4gl
 * Purpose: Main orchestrator module for User Activity Analyzer
 * Context: Based on main module patterns from knowledge_base.JSON
 * Style: snake_case, 2-space indentation per project standards
 * 
 * Module Overview:
 * ===============
 * This module implements a User Activity Analyzer that:
 * 1. Loads user IDs from database
 * 2. Loads last login timestamps for each user
 * 3. Categorizes users as ACTIVE/DORMANT/INACTIVE
 * 4. Stores results in temporary in-memory structure
 * 5. Writes inactive users to inactive_log table
 * 6. Returns summary statistics
 *
 * Architecture:
 * =============
 * - user_activity_constants: Category labels, time thresholds, table names
 * - user_activity_util: Helper functions (validation, date calc, categorization)
 * - user_activity_loader: Data loading from database
 * - user_activity_db_writer: Writing inactive users to log
 * - user_activity_summary: Summary statistics generation
 * - user_activity_analyzer: Main orchestration (this module)
 *}

IMPORT FGL user_activity_constants
IMPORT FGL user_activity_util
IMPORT FGL user_activity_loader
IMPORT FGL user_activity_db_writer
IMPORT FGL user_activity_summary

SCHEMA records

{* Function: analyze_user_activity
 * Purpose: Main entry point for user activity analysis
 * Pattern: Orchestration pattern following knowledge_base.JSON
 * Returns: Summary statistics record, or NULL on error
 * 
 * Process Flow:
 * 1. Load all user activity data
 * 2. Store results in memory (as dynamic array)
 * 3. Log inactive users to database
 * 4. Calculate and return summary statistics
 *}
PUBLIC FUNCTION analyze_user_activity() 
  RETURNS user_activity_summary.t_activity_summary
  DEFINE l_activities DYNAMIC ARRAY OF user_activity_loader.t_user_activity
  DEFINE l_summary user_activity_summary.t_activity_summary
  DEFINE l_logged_count INTEGER
  
  -- Step 1: Load user activity data
  -- This loads user IDs, last login timestamps, and calculates days since login
  LET l_activities = user_activity_loader.load_all_user_activity()
  
  -- Check if we got any data
  IF l_activities.getLength() = 0 THEN
    DISPLAY "Warning: No user activity data found"
    -- Return empty summary
    LET l_summary.total_users = 0
    LET l_summary.active_count = 0
    LET l_summary.dormant_count = 0
    LET l_summary.inactive_count = 0
    LET l_summary.oldest_last_login = NULL
    RETURN l_summary
  END IF
  
  -- Step 2: Results are already in memory (l_activities array)
  -- User categorization happened during load
  
  -- Step 3: Write inactive users to database log table
  LET l_logged_count = user_activity_db_writer.log_inactive_users_batch(l_activities)
  
  IF l_logged_count < 0 THEN
    DISPLAY "Error: Failed to log inactive users to database"
    -- Continue to return summary even if logging failed
  ELSE
    DISPLAY "Logged ", l_logged_count, " inactive users to database"
  END IF
  
  -- Step 4: Calculate summary statistics
  LET l_summary = user_activity_summary.calculate_summary_statistics(l_activities)
  
  RETURN l_summary
END FUNCTION

{* Function: run_analysis_and_report
 * Purpose: Run analysis and display report to console
 * Pattern: Convenience function following knowledge_base.JSON patterns
 * Returns: Error code (C_ERR_SUCCESS or error code)
 *}
PUBLIC FUNCTION run_analysis_and_report() RETURNS INTEGER
  DEFINE l_summary user_activity_summary.t_activity_summary
  
  DISPLAY "Starting User Activity Analysis..."
  DISPLAY "=================================="
  
  -- Run analysis
  LET l_summary = analyze_user_activity()
  
  -- Display results
  CALL user_activity_summary.print_summary_report(l_summary)
  
  DISPLAY "Analysis complete."
  
  RETURN user_activity_constants.C_ERR_SUCCESS
END FUNCTION

{* Main Program
 * Purpose: Entry point when module is executed directly
 * Pattern: Based on main patterns from knowledge_base.JSON
 *}
MAIN
  DEFINE l_result INTEGER
  
  -- Run analysis with report
  LET l_result = run_analysis_and_report()
  
  -- Exit with appropriate code
  IF l_result != user_activity_constants.C_ERR_SUCCESS THEN
    EXIT PROGRAM l_result
  END IF
END MAIN
