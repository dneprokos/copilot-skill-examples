# Token Usage Report Template

## Summary for {TIME_PERIOD}

| Metric             | Value             | Notes                    |
| ------------------ | ----------------- | ------------------------ |
| **Period**         | {PERIOD_DISPLAY}  | {PERIOD_DESCRIPTION}     |
| **Total Tokens**   | {TOTAL_TOKENS}    | All token consumption    |
| **Average/Day**    | {AVG_PER_DAY}     | Daily average            |
| **Peak Day**       | {PEAK_DATE}       | Highest usage day        |
| **Peak Tokens**    | {PEAK_TOKENS}     | Maximum daily tokens     |
| **Estimated Cost** | ${ESTIMATED_COST} | Based on current pricing |

## Daily Breakdown

| Date | Tokens Used | % of Period | Cumulative | Notes |
| ---- | ----------- | ----------- | ---------- | ----- |

{DAILY_ROWS}

## Usage Categories

| Category           | Tokens         | Percentage          | Description         |
| ------------------ | -------------- | ------------------- | ------------------- |
| **API Calls**      | {API_TOKENS}   | {API_PERCENTAGE}%   | Direct API requests |
| **Authentication** | {AUTH_TOKENS}  | {AUTH_PERCENTAGE}%  | Login/token refresh |
| **Test Execution** | {TEST_TOKENS}  | {TEST_PERCENTAGE}%  | Automated testing   |
| **Other**          | {OTHER_TOKENS} | {OTHER_PERCENTAGE}% | Miscellaneous usage |

## Trends & Insights

{TRENDS_SECTION}

---

**Report Generated:** {GENERATION_TIMESTAMP}  
**Data Source:** {DATA_SOURCE}  
**Next Update:** {NEXT_UPDATE}
