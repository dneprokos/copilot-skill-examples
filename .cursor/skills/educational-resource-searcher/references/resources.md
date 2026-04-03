# Educational Platforms Reference

This file lists supported educational platforms for the educational-resource-searcher skill. Each platform includes search URL template, extraction hints for results, filtering notes, and the fetch strategy to use.

## YouTube

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:youtube.com {topic} {language} course tutorial`. Direct fetch returns an empty HTML shell; YouTube renders results via JavaScript.
- **Site domain**: youtube.com
- **Search URL**: https://www.youtube.com/results?search_query={topic}+{language}&sp=CAASAhAB (for reference only; not fetched directly)
- **Extraction**: Extract titles and links from WebSearch result snippets. Views and ratings are not always available in snippets; use view counts when present.
- **Free/Paid**: All free.
- **Language**: Include in the search query, e.g., "sql basics ukrainian".

## Udemy

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:udemy.com {topic} {language} course`. Direct fetch is blocked or returns a JS-only shell.
- **Site domain**: udemy.com
- **Search URL**: https://www.udemy.com/courses/search/?q={topic}&lang={language} (for reference only; not fetched directly)
- **Extraction**: Extract titles, links, ratings, and enrollments from WebSearch result snippets.
- **Free/Paid**: Check snippet for price indicators; assume paid unless snippet explicitly shows "Free".
- **Language**: Include language in the search query.

## LinkedIn Learning

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:linkedin.com/learning {topic} course`. Requires authentication; direct fetch returns a login redirect.
- **Site domain**: linkedin.com/learning
- **Search URL**: https://www.linkedin.com/learning/search?keywords={topic}&trk=learning-course-list&upsellOrderBy=most_popular (for reference only; not fetched directly)
- **Extraction**: Extract titles and links from WebSearch result snippets.
- **Free/Paid**: Requires subscription; assume paid unless specified.
- **Language**: Include language in the search query.

## Pluralsight

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:pluralsight.com {topic} course`. Direct fetch returns navigation-only HTML with no course results.
- **Site domain**: pluralsight.com
- **Search URL**: https://www.pluralsight.com/search?q={topic}&type=courses (for reference only; not fetched directly)
- **Extraction**: Extract titles, links, and ratings from WebSearch result snippets.
- **Free/Paid**: Subscription required.
- **Language**: Limited support; include in search query if needed.

## W3Schools

- **Fetch Strategy**: WebFetch — fetch the search URL directly and extract results from the returned HTML. W3Schools uses server-side rendering.
- **Search URL**: https://www.w3schools.com/search/search.php?q={topic}
- **Extraction**: Tutorials in `<a>` links; no ratings or views directly; prioritize by relevance.
- **Free/Paid**: All free.
- **Language**: English only.

## Coursera

- **Fetch Strategy**: WebFetch — fetch the search URL directly and extract results from the returned HTML. Coursera uses server-side rendering for course listings.
- **Search URL**: https://www.coursera.org/courses?query={topic}
- **Extraction**: Course titles in `<a>` with "course-title", ratings in "ratings" div, enrollments in "enrollment" spans.
- **Free/Paid**: Check for "Free" badge or audit option.
- **Language**: Add `&languages={language}` to the URL.

## edX

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:edx.org {topic} course`. Direct fetch returns a JS-rendered shell with no course data.
- **Site domain**: edx.org
- **Search URL**: https://www.edx.org/search?tab=course&q={topic} (for reference only; not fetched directly)
- **Extraction**: Extract titles, links, and free/paid status from WebSearch result snippets.
- **Free/Paid**: Many free; check snippet for "Free" or audit option.
- **Language**: Include language in the search query.

## Khan Academy

- **Fetch Strategy**: WebSearch — use the `WebSearch` tool with query `site:khanacademy.org {topic}`. Direct fetch returns limited results; WebSearch gives better coverage.
- **Site domain**: khanacademy.org
- **Search URL**: https://www.khanacademy.org/search?page_search_query={topic} (for reference only; not fetched directly)
- **Extraction**: Extract topic titles and links from WebSearch result snippets.
- **Free/Paid**: All free.
- **Language**: Limited; mostly English.

To add new platforms, follow this format and update the skill to handle them. See the "Fetch strategy notes" section in SKILL.md for guidance on choosing the correct fetch strategy.
