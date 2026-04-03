---
name: educational-resource-searcher
description: >-
  Search for highly-rated educational resources on topics like programming, math, or business.
  Use this skill whenever users ask to find tutorials, courses, videos, or learning materials on specific topics,
  especially when mentioning platforms like YouTube, Udemy, LinkedIn Learning, Pluralsight, W3Schools, Coursera, edX, or Khan Academy.
  Always trigger when users want to learn something new and need curated, top-rated resources with filters for language, platform, free/paid, and result limits.
---

# Educational Resource Searcher

This skill searches popular educational platforms for high-quality learning resources based on user-specified topics, with optional filters for language, platform, free/paid status, and maximum results.

## When this skill fits

- User asks to find tutorials, courses, videos, or learning materials on a specific topic (e.g., "SQL basics", "machine learning").
- Requests include filters like language ("in Ukrainian"), platform ("on YouTube"), free/paid ("free videos"), or max results.
- Queries about learning resources, educational content, or skill-building materials.
- Do NOT use for general web searches, non-educational content, or when no topic is specified.

## Workflow

1. Parse the user's query to extract parameters:
   - **topics**: Required, at least one (e.g., "SQL database basics").
   - **language**: Optional, default "english".
   - **platforms**: Optional, list from references/resources.md; default all.
   - **max_items**: Optional, default 5.
   - **free_only**: Optional, boolean; default false (include paid).

2. Validate: If no topics provided, return error message: "You need to specify at least one topic."

3. Load platform details from `references/resources.md`.

4. For each selected platform, check its **Fetch Strategy** in `references/resources.md` and apply the matching approach:
   - **WebFetch platforms** (Coursera, W3Schools): Construct the search URL from the template and fetch the page directly using the `WebFetch` tool. Extract results from the returned HTML.
   - **WebSearch platforms** (YouTube, Udemy, LinkedIn Learning, Pluralsight, edX, Khan Academy): Use the `WebSearch` tool with the query pattern `site:{platform_domain} {topic} {language} course tutorial`. Extract titles, links, ratings, and metadata from the search result snippets returned.
   - For both strategies: collect title, link, rating (if available), views/enrollments, free/paid status. Filter results based on free_only and language (if detectable).

5. Aggregate results from all platforms.

6. Sort by rating descending, then views/enrollments descending.

7. Limit to max_items.

8. Output in ASCII table format.

## Hard rules

- Always require at least one topic; return error otherwise.
- Default language: English.
- Default max_items: 5.
- Default platforms: All listed in references.
- Prioritize highest rated and most viewed resources.
- Only include resources with valid links.
- If no results found, output: "No educational resources found for the specified criteria."

## Output format

Return a Markdown table:

| Platform | Title               | Link        | Rating | Views | Free/Paid |
| -------- | ------------------- | ----------- | ------ | ----- | --------- |
| YouTube  | SQL Basics Tutorial | https://... | 4.8    | 1.2M  | Free      |
| ...      | ...                 | ...         | ...    | ...   | ...       |

## Examples

**Input:** "find sql database basics on youtube in ukrainian language free video"

**Output:**
| Platform | Title | Link | Rating | Views | Free/Paid |
|----------|-------|------|--------|-------|-----------|
| YouTube | SQL Basics in Ukrainian | https://youtube.com/watch?v=abc | 4.5 | 50K | Free |

**Input:** "tutorials on python programming, free only, max 3"

**Output:** (Table with up to 3 free Python resources from various platforms)

## Fetch strategy notes

Many educational platforms render search results client-side via JavaScript. The `WebFetch` tool only retrieves the initial static HTML, so it returns an empty shell with no results for these sites. The skill uses two strategies:

- **WebFetch**: For platforms that server-render their search results (currently Coursera and W3Schools). Faster and returns structured HTML.
- **WebSearch**: For JS-heavy platforms (YouTube, Udemy, LinkedIn Learning, Pluralsight, edX, Khan Academy). Uses a search engine query with a `site:` filter to retrieve indexed, pre-rendered results from snippets. Less structured than parsed HTML but reliable across all browsers and auth walls.

If a `WebFetch` call returns only navigation and footer content with no actual results, the platform is JS-rendered and must be switched to the `WebSearch` strategy.

## Extending this skill

To add new platforms, update `references/resources.md` with the new entry following the existing format. Always include:

1. The **Fetch Strategy** (`WebFetch` or `WebSearch`) — test by attempting a `WebFetch` on the platform's search URL. If the result contains no course/video listings, the platform requires `WebSearch`.
2. The **Site domain** (for `WebSearch` platforms), used in the `site:` filter query.
3. The **Search URL template** (kept for reference even for `WebSearch` platforms).

The skill will automatically include the new platform in all searches once added.
