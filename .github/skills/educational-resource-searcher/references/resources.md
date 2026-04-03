# Educational Platforms Reference

This file lists supported educational platforms for the educational-resource-searcher skill. Each platform includes search URL template, extraction hints for results, and filtering notes.

## YouTube

- **Search URL**: https://www.youtube.com/results?search_query={topic}+{language}&sp=CAASAhAB (sort by relevance, but we can adjust for views)
- **Extraction**: Look for video titles in <a> tags with class "yt-simple-endpoint", links are href="/watch?v=...", views in spans with "view-count", ratings not directly available but can estimate from thumbs up.
- **Free/Paid**: All free.
- **Language**: Include in search_query, e.g., "sql basics ukrainian".

## Udemy

- **Search URL**: https://www.udemy.com/courses/search/?q={topic}&lang={language}
- **Extraction**: Course titles in <a> with class "course-card--course-title", links are href, ratings in spans with "star-rating", enrollments in "enrollment" spans, price indicates free/paid.
- **Free/Paid**: Check if price is 0 or "Free".
- **Language**: Use lang parameter.

## LinkedIn Learning

- **Search URL**: https://www.linkedin.com/learning/search?keywords={topic}&trk=learning-course-list&upsellOrderBy=most_popular
- **Extraction**: Titles in <a> with "course-card\_\_title", links are href, ratings in "ratings" div, viewers in "enrollments".
- **Free/Paid**: Requires subscription, but some free trials; assume paid unless specified.
- **Language**: Add &entityLanguage={language}

## Pluralsight

- **Search URL**: https://www.pluralsight.com/search?q={topic}&type=courses
- **Extraction**: Titles in <a> with "course-title", ratings in "rating" spans, views in "students" spans.
- **Free/Paid**: Subscription required.
- **Language**: Limited support.

## W3Schools

- **Search URL**: https://www.w3schools.com/search/search.php?q={topic}
- **Extraction**: Tutorials in <a> links, no ratings/views directly, prioritize by relevance.
- **Free/Paid**: All free.
- **Language**: English only.

## Coursera

- **Search URL**: https://www.coursera.org/courses?query={topic}
- **Extraction**: Course titles in <a> with "course-title", ratings in "ratings" div, enrollments in "enrollment" spans.
- **Free/Paid**: Check for "Free" badge or audit option.
- **Language**: Add &languages={language}

## edX

- **Search URL**: https://www.edx.org/search?tab=course&q={topic}
- **Extraction**: Titles in <a> with "course-title", ratings if available, enrollments.
- **Free/Paid**: Many free, check for "Free" or audit.
- **Language**: Add &language={language}

## Khan Academy

- **Search URL**: https://www.khanacademy.org/search?page_search_query={topic}
- **Extraction**: Topics in <a> links, no ratings, views not direct.
- **Free/Paid**: All free.
- **Language**: Limited, mostly English.

To add new platforms, follow this format and update the skill to handle them.
