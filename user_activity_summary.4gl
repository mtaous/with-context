{* Name: user_activity_summary.4gl
 * Purpose: Summary statistics generator for User Activity Analyzer
 * Context: Based on utility function patterns from knowledge_base.JSON
 * Style: snake_case, 2-space indentation per project standards
 *}

IMPORT FGL user_activity_constants
IMPORT FGL user_activity_loader

SCHEMA records

-- Summary statistics record structure
-- Pattern: Custom RECORD type per knowledge_base.JSON patterns
PUBLIC TYPE t_activity_summary RECORD
  total_users INTEGER,
  active_count INTEGER,
  dormant_count INTEGER,
  inactive_count INTEGER,
  oldest_last_login DATETIME YEAR TO SECOND
END RECORD

{* Function: calculate_summary_statistics
 * Purpose: Build summary statistics from user activity data
 * Pattern: Based on data processing patterns from knowledge_base.JSON
 * Args: p_activities - array of user activity records
 * Returns: Summary statistics record
 * Logic: Iterates through activities to count categories and find oldest login
 *}
PUBLIC FUNCTION calculate_summary_statistics(
  p_activities DYNAMIC ARRAY OF user_activity_loader.t_user_activity
) RETURNS t_activity_summary
  DEFINE l_summary t_activity_summary
  DEFINE l_idx INTEGER
  DEFINE l_activity user_activity_loader.t_user_activity
  
  -- Initialize summary counters
  LET l_summary.total_users = 0
  LET l_summary.active_count = 0
  LET l_summary.dormant_count = 0
  LET l_summary.inactive_count = 0
  LET l_summary.oldest_last_login = NULL
  
  -- Process each activity record
  FOR l_idx = 1 TO p_activities.getLength()
    LET l_activity = p_activities[l_idx]
    
    -- Count total users
    LET l_summary.total_users = l_summary.total_users + 1
    
    -- Count by category
    CASE l_activity.category
      WHEN user_activity_constants.C_CATEGORY_ACTIVE
        LET l_summary.active_count = l_summary.active_count + 1
      WHEN user_activity_constants.C_CATEGORY_DORMANT
        LET l_summary.dormant_count = l_summary.dormant_count + 1
      WHEN user_activity_constants.C_CATEGORY_INACTIVE
        LET l_summary.inactive_count = l_summary.inactive_count + 1
    END CASE
    
    -- Track oldest last login
    IF l_activity.last_login IS NOT NULL THEN
      IF l_summary.oldest_last_login IS NULL THEN
        LET l_summary.oldest_last_login = l_activity.last_login
      ELSE
        IF l_activity.last_login < l_summary.oldest_last_login THEN
          LET l_summary.oldest_last_login = l_activity.last_login
        END IF
      END IF
    END IF
  END FOR
  
  RETURN l_summary
END FUNCTION

{* Function: format_summary_report
 * Purpose: Format summary statistics as human-readable string
 * Pattern: Based on format functions from ac_util.4gl patterns
 * Args: p_summary - summary statistics record
 * Returns: Formatted string representation
 *}
PUBLIC FUNCTION format_summary_report(p_summary t_activity_summary) 
  RETURNS STRING
  DEFINE l_report STRING
  DEFINE l_oldest_str STRING
  
  -- Format oldest login timestamp with explicit conversion
  IF p_summary.oldest_last_login IS NULL THEN
    LET l_oldest_str = "N/A"
  ELSE
    LET l_oldest_str = p_summary.oldest_last_login USING "YYYY-MM-DD HH24:MI:SS"
  END IF
  
  -- Build formatted report
  LET l_report = "User Activity Summary Report\n",
                 "=============================\n",
                 "Total Users:    ", p_summary.total_users, "\n",
                 "Active:         ", p_summary.active_count, "\n",
                 "Dormant:        ", p_summary.dormant_count, "\n",
                 "Inactive:       ", p_summary.inactive_count, "\n",
                 "Oldest Login:   ", l_oldest_str, "\n"
  
  RETURN l_report
END FUNCTION

{* Function: print_summary_report
 * Purpose: Display summary report to console
 * Pattern: Based on DISPLAY patterns from knowledge_base.JSON
 * Args: p_summary - summary statistics record
 *}
PUBLIC FUNCTION print_summary_report(p_summary t_activity_summary)
  DEFINE l_report STRING
  
  LET l_report = format_summary_report(p_summary)
  DISPLAY l_report
END FUNCTION
