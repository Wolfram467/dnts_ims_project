# DNTS IMS Context & Code Generation Standards

When generating, editing, or refactoring code for the DNTS Inventory Management System, you MUST strictly adhere to the following naming and structural principles:

## 1. Express Intent Clearly
- **Avoid Single-Letter Names:** Code is read more often than it is written. Never use single-letter variables (e.g., `i`, `x`, `n`) except in standard, extremely short loop constraints. Use descriptive names that convey intent.

## 2. No Abbreviations
- **Never Abbreviate:** Do not shorten words. Screen real estate and IDE auto-complete make abbreviations obsolete. 
  - *Bad:* `navBtnInv`, `req`, `authCtx`
  - *Good:* `inventoryNavigationButton`, `request`, `authenticationContext`

## 3. No Type Encoding (Hungarian Notation)
- **Avoid Types in Names:** Do not prefix or suffix variables with their data type or widget type. Let the static typing system do its job.
  - *Bad:* `strName`, `arrDesks`, `btnSubmit`, `txtHeader`
  - *Good:* `name`, `desks`, `submitAction`, `headerLabel`

## 4. Use Descriptive Units
- **Include Units for Measurements:** If a variable represents a quantifiable measurement (time, distance, etc.), explicitly append the unit to the name.
  - *Bad:* `timeout`, `delay`, `radius`
  - *Good:* `timeoutMilliseconds`, `delaySeconds`, `radiusPixels`

## 5. Simplify Type Names
- **No 'I', 'Base', or 'Abstract' Prefixes:** Do not prefix interfaces with "I" or parent classes with "Base"/"Abstract". 
  - *Bad:* `IDatabaseService`, `BaseWidget`
  - *Good:* `DatabaseService`, `CoreWidget`

## 6. Structural Grouping (No "Utils")
- **Eliminate 'Utils' and 'Helper' Classes:** Do not group code into generic "Utility" or "Helper" files. If functions do not fit into an existing class, create a dedicated domain-specific class or extension.
  - *Bad:* `FormatUtils`, `MapHelpers`
  - *Good:* `DateFormatter`, `CoordinateCalculator`
  