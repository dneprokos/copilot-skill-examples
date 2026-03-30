# Token Usage Reporting Skill

A VS Code agent skill for generating comprehensive token usage reports in table format.

## Overview

This skill generates detailed token usage reports for different time periods (daily, weekly, monthly) with formatted tables, cost estimates, and usage analytics.

## Features

- 📊 **Multiple Time Periods**: Generate reports for today, week, or month
- 💰 **Cost Estimation**: Calculate estimated costs based on token pricing
- 📈 **Usage Analytics**: Track trends, peaks, and patterns
- 🎨 **Customizable Templates**: Modify table formatting and styling
- 🔧 **Configurable Data Sources**: Support for API logs, environment variables, test traces

## Usage

### As VS Code Agent Skill

```
/token-usage-reporting today
/token-usage-reporting week
/token-usage-reporting month
```

### Command Line Usage

```bash
# Generate today's report
node .github/skills/token-usage-reporting/scripts/generate-report.js today

# Generate weekly report
node .github/skills/token-usage-reporting/scripts/generate-report.js week

# Generate monthly report
node .github/skills/token-usage-reporting/scripts/generate-report.js month
```

## Configuration

### Data Sources (`config/token-sources.json`)

Configure where to collect token usage data from:

- **Playwright traces**: Extract from test execution traces
- **API logs**: Parse structured log files
- **Environment variables**: Read from system environment
- **Custom patterns**: Define file patterns for categorization

### Pricing Configuration

Set token pricing for cost calculations:

```json
{
  "pricing": {
    "tokenCostPer1K": 0.002,
    "currency": "USD"
  }
}
```

### Usage Categories

Define patterns to categorize token usage:

- **API calls**: Direct endpoint requests
- **Authentication**: Login and token refresh
- **Test execution**: Automated testing overhead
- **Other**: Miscellaneous usage

## Template Customization

The `templates/usage-table.md` file defines the report format with variable placeholders:

| Variable           | Description               |
| ------------------ | ------------------------- |
| `{TIME_PERIOD}`    | Report time period        |
| `{TOTAL_TOKENS}`   | Total token consumption   |
| `{AVG_PER_DAY}`    | Daily average usage       |
| `{ESTIMATED_COST}` | Calculated cost estimate  |
| `{DAILY_ROWS}`     | Generated daily breakdown |
| `{TRENDS_SECTION}` | Usage analytics           |

## File Structure

```
.github/skills/token-usage-reporting/
├── SKILL.md              # Skill definition
├── README.md             # This file
├── config/
│   └── token-sources.json # Data source configuration
├── templates/
│   └── usage-table.md    # Report table template
└── scripts/
    └── generate-report.js # Report generation script
```

## Integration with Test Framework

The skill integrates with your Playwright test framework by:

- Reading token usage from test execution logs
- Categorizing usage by test type (smoke tests vs API tests)
- Tracking authentication token refresh patterns
- Monitoring API endpoint usage during testing

## Sample Output

```markdown
## Summary for today

| Metric             | Value          | Notes                    |
| ------------------ | -------------- | ------------------------ |
| **Period**         | March 18, 2026 | Single day report        |
| **Total Tokens**   | 12,547         | All token consumption    |
| **Average/Day**    | 12,547.0       | Daily average            |
| **Peak Day**       | 2026-03-18     | Highest usage day        |
| **Peak Tokens**    | 12,547         | Maximum daily tokens     |
| **Estimated Cost** | $0.03          | Based on current pricing |
```

## Development

To extend or modify the skill:

1. Update `SKILL.md` for new procedures
2. Modify `templates/usage-table.md` for different formatting
3. Extend `config/token-sources.json` for new data sources
4. Update `scripts/generate-report.js` for additional analytics

The skill follows VS Code agent customization best practices with progressive loading and keyword-rich descriptions for discoverability.
