#!/usr/bin/env node

/**
 * Token Usage Data Generator
 * Generates sample token usage data for testing the reporting skill
 */

const fs = require("fs");
const path = require("path");

class TokenUsageGenerator {
  constructor() {
    this.baseDir = path.resolve(__dirname, "..");
    this.configPath = path.join(this.baseDir, "config", "token-sources.json");
    this.config = this.loadConfig();
  }

  loadConfig() {
    try {
      return JSON.parse(fs.readFileSync(this.configPath, "utf8"));
    } catch (error) {
      console.error("Failed to load config:", error.message);
      return this.getDefaultConfig();
    }
  }

  getDefaultConfig() {
    return {
      pricing: { tokenCostPer1K: 0.002, currency: "USD" },
      reporting: { timezone: "UTC", dateFormat: "YYYY-MM-DD" },
    };
  }

  generateUsageData(period = "today") {
    const now = new Date();
    let startDate, endDate, days;

    switch (period) {
      case "today":
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        endDate = new Date(startDate.getTime() + 24 * 60 * 60 * 1000);
        days = 1;
        break;
      case "week":
        const dayOfWeek = now.getDay();
        startDate = new Date(now.getTime() - dayOfWeek * 24 * 60 * 60 * 1000);
        startDate.setHours(0, 0, 0, 0);
        endDate = new Date(startDate.getTime() + 7 * 24 * 60 * 60 * 1000);
        days = 7;
        break;
      case "month":
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        endDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        days = Math.floor((endDate - startDate) / (24 * 60 * 60 * 1000));
        break;
      default:
        throw new Error(`Unknown period: ${period}`);
    }

    return this.simulateUsageData(startDate, endDate, days);
  }

  simulateUsageData(startDate, endDate, days) {
    const data = {
      period: {
        start: startDate.toISOString().split("T")[0],
        end: endDate.toISOString().split("T")[0],
        days: days,
      },
      usage: {
        total: 0,
        byDate: {},
        byCategory: {
          api: Math.floor(Math.random() * 5000) + 2000,
          auth: Math.floor(Math.random() * 1000) + 500,
          test: Math.floor(Math.random() * 2000) + 800,
          other: Math.floor(Math.random() * 500) + 100,
        },
      },
    };

    // Generate daily usage data
    for (let i = 0; i < days; i++) {
      const date = new Date(startDate.getTime() + i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split("T")[0];
      const dailyTokens = Math.floor(Math.random() * 3000) + 1000;

      data.usage.byDate[dateStr] = dailyTokens;
      data.usage.total += dailyTokens;
    }

    return data;
  }

  formatReport(data, period) {
    const templatePath = path.join(this.baseDir, "templates", "usage-table.md");
    let template = fs.readFileSync(templatePath, "utf8");

    // Calculate metrics
    const avgPerDay = data.usage.total / data.period.days;
    const dailyValues = Object.values(data.usage.byDate);
    const peakTokens = Math.max(...dailyValues);
    const peakDate = Object.keys(data.usage.byDate).find(
      (date) => data.usage.byDate[date] === peakTokens,
    );

    const estimatedCost =
      (data.usage.total / 1000) * this.config.pricing.tokenCostPer1K;

    // Build daily rows
    const dailyRows = Object.entries(data.usage.byDate)
      .map(([date, tokens]) => {
        const percentage = ((tokens / data.usage.total) * 100).toFixed(1);
        const cumulative = Object.entries(data.usage.byDate)
          .filter(([d]) => d <= date)
          .reduce((sum, [, t]) => sum + t, 0);
        return `| ${date} | ${tokens.toLocaleString()} | ${percentage}% | ${cumulative.toLocaleString()} | - |`;
      })
      .join("\n");

    // Calculate category percentages
    const totalCategoryTokens = Object.values(data.usage.byCategory).reduce(
      (sum, tokens) => sum + tokens,
      0,
    );

    // Replace template variables
    const replacements = {
      "{TIME_PERIOD}": period,
      "{PERIOD_DISPLAY}": `${data.period.start} to ${data.period.end}`,
      "{PERIOD_DESCRIPTION}": `${data.period.days} day${data.period.days > 1 ? "s" : ""}`,
      "{TOTAL_TOKENS}": data.usage.total.toLocaleString(),
      "{AVG_PER_DAY}": avgPerDay.toFixed(1),
      "{PEAK_DATE}": peakDate,
      "{PEAK_TOKENS}": peakTokens.toLocaleString(),
      "{ESTIMATED_COST}": estimatedCost.toFixed(2),
      "{DAILY_ROWS}": dailyRows,
      "{API_TOKENS}": data.usage.byCategory.api.toLocaleString(),
      "{API_PERCENTAGE}": (
        (data.usage.byCategory.api / totalCategoryTokens) *
        100
      ).toFixed(1),
      "{AUTH_TOKENS}": data.usage.byCategory.auth.toLocaleString(),
      "{AUTH_PERCENTAGE}": (
        (data.usage.byCategory.auth / totalCategoryTokens) *
        100
      ).toFixed(1),
      "{TEST_TOKENS}": data.usage.byCategory.test.toLocaleString(),
      "{TEST_PERCENTAGE}": (
        (data.usage.byCategory.test / totalCategoryTokens) *
        100
      ).toFixed(1),
      "{OTHER_TOKENS}": data.usage.byCategory.other.toLocaleString(),
      "{OTHER_PERCENTAGE}": (
        (data.usage.byCategory.other / totalCategoryTokens) *
        100
      ).toFixed(1),
      "{TRENDS_SECTION}": this.generateTrends(data),
      "{GENERATION_TIMESTAMP}": new Date().toISOString(),
      "{DATA_SOURCE}": "Simulated test data",
      "{NEXT_UPDATE}": "Next scheduled run",
    };

    // Apply replacements
    Object.entries(replacements).forEach(([placeholder, value]) => {
      template = template.replace(
        new RegExp(placeholder.replace(/[{}]/g, "\\$&"), "g"),
        value,
      );
    });

    return template;
  }

  generateTrends(data) {
    const dailyValues = Object.values(data.usage.byDate);
    const trend =
      dailyValues.length > 1
        ? dailyValues[dailyValues.length - 1] > dailyValues[0]
          ? "increasing"
          : "decreasing"
        : "stable";

    return `- **Overall Trend:** Token usage is ${trend} over the period
- **Peak Usage:** ${Math.max(...dailyValues).toLocaleString()} tokens
- **Lowest Usage:** ${Math.min(...dailyValues).toLocaleString()} tokens
- **Variability:** ${(Math.max(...dailyValues) / Math.min(...dailyValues)).toFixed(1)}x difference between peak and low`;
  }
}

// CLI interface
if (require.main === module) {
  const period = process.argv[2] || "today";
  const generator = new TokenUsageGenerator();

  try {
    const data = generator.generateUsageData(period);
    const report = generator.formatReport(data, period);
    console.log(report);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

module.exports = TokenUsageGenerator;
