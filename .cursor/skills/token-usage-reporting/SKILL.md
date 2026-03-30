---
name: token-usage-reporting
description: "Generate token usage reports in table format for different time periods. Use for tracking API token consumption, analyzing usage patterns, monitoring token costs by day/week/month periods."
argument-hint: "time period: today|week|month"
---

# Token Usage Reporting

## When to Use

- Track API token consumption over time
- Generate usage reports for cost analysis
- Monitor token usage patterns and trends
- Create formatted tables for documentation or reporting
- Analyze token usage by time periods (daily, weekly, monthly)

## Procedure

### 1. Generate Usage Report

The skill generates token usage reports in a formatted table showing:

- Time period (today, this week, this month)
- Total tokens consumed
- Average tokens per day
- Peak usage periods
- Cost estimates (if token pricing configured)

### 2. Time Period Options

- `today` - Current day's token usage
- `week` - Current week's cumulative usage
- `month` - Current month's cumulative usage

### 3. Output Format

Reports use the standardized [table template](./templates/usage-table.md) for consistent formatting across different time periods.

### 4. Data Sources

The skill can aggregate token usage from:

- API request logs
- Environment variables with usage tracking
- Configuration files with token consumption data
- Test execution reports with token metrics

## Usage Examples

```bash
# Generate today's usage report
/token-usage-reporting today

# Generate weekly usage report
/token-usage-reporting week

# Generate monthly usage report
/token-usage-reporting month
```

## Configuration

Token usage data can be configured through:

- Environment variables (`TOKEN_USAGE_LOG_PATH`)
- Configuration files in `./config/`
- Integration with existing logging systems

## Template Customization

Modify the [table template](./templates/usage-table.md) to customize:

- Column headers and formatting
- Date/time display formats
- Additional metrics or calculations
- Styling and visual presentation
