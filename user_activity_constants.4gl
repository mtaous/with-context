{* Name: user_activity_constants.4gl
 * Purpose: Constants for User Activity Analyzer module
 * Context: Based on knowledge_base.JSON patterns and sql_best_practices.json
 * Style: snake_case naming, 2-space indentation per project standards
 *}

SCHEMA records

-- Activity category constants
-- Source: Project requirement specification
PUBLIC CONSTANT C_CATEGORY_ACTIVE = "ACTIVE"
PUBLIC CONSTANT C_CATEGORY_DORMANT = "DORMANT"
PUBLIC CONSTANT C_CATEGORY_INACTIVE = "INACTIVE"

-- Time threshold constants (in days)
-- Source: Project requirement specification
PUBLIC CONSTANT C_THRESHOLD_ACTIVE_DAYS = 7
PUBLIC CONSTANT C_THRESHOLD_DORMANT_DAYS = 30

-- Table name constants
-- Source: sql_best_practices.json - use lowercase table names
PUBLIC CONSTANT C_TABLE_USERS = "users"
PUBLIC CONSTANT C_TABLE_USER_LOGINS = "user_logins"
PUBLIC CONSTANT C_TABLE_INACTIVE_LOG = "inactive_log"

-- Error code constants
-- Inferred from knowledge_base.JSON error handling patterns
PUBLIC CONSTANT C_ERR_SUCCESS = 0
PUBLIC CONSTANT C_ERR_NO_DATA = -1
PUBLIC CONSTANT C_ERR_DATABASE = -2
PUBLIC CONSTANT C_ERR_INVALID_INPUT = -3
