# REST API design — extended reference

Use this file when a full review, deep checklist, or OpenAPI/documentation pass is needed. It merges common REST guidance with stricter conventions from internal API guideline documents.

## Endpoint paths

- **Nouns, not verbs** — Paths name **resources** (`/flowsheets`), not actions (`/getFlowsheets`).
- **Plural collections** — `/users` not `/user` for the collection.
- **Hierarchy** — Use `/` for parent/child (`/flowsheets/{flowsheetId}/units/{unitId}`). Avoid alternative “fake hierarchy” via query when path semantics are clearer.
- **Avoid deep nesting** — More than two or three path segments under a root resource often signals a **flat** resource with filters is simpler (e.g. `/nodes?flowsheetId={id}` instead of four levels of nesting). Prefer flat models unless the nested identity is truly hierarchical.

## Parameters

- **Query** for filters, sort, search, pagination—not for large or sensitive payloads.
- **Consistent naming** — Pick **camelCase** or **snake_case** for the whole API and stick to it; avoid mixed `Created-At` vs `createdAt`.
- **Standard pagination query names** when using page style: e.g. `page`, `pageSize` (or `limit`/`offset` if documented). Cap `pageSize` with a documented maximum.

## Pagination strategies

| Style        | When to prefer                                      | Response hints                          |
| ------------ | --------------------------------------------------- | --------------------------------------- |
| Cursor-based | Large collections, frequent inserts, stable paging | `nextCursor`, `hasMore`, `limit`        |
| Page / offset| Simpler clients, smaller datasets                   | `page`, `pageSize`, `totalItems`, `totalPages` |

**Validation messages (page style)** — Return clear client errors, for example:

- `page` cannot be less than 1
- `page` cannot exceed maximum allowed page
- `pageSize` cannot be less than 1
- `pageSize` cannot exceed {max}

## Filtering and sorting

- Express filters via **query parameters** (`category=electronics`, `price_lt=100`).
- If using operator suffixes (`_lt`, `_gt`, etc.), document them in OpenAPI and stay consistent.

## Versioning

- Prefer **integer version in the URL path** (e.g. `/v1/orders`, `/api/v1/users`).
- Avoid relying on **version only in query strings or custom headers** as the sole mechanism—URL path versioning is easier to see in documentation and logs.
- Reflect the same version in **OpenAPI** `servers` or path prefixes.

## Error handling

- Return **meaningful** messages and the **correct HTTP status** (not `200` with an error body).
- For validation failures, include **field-level** detail when helpful.
- **RFC 9457** (*Problem Details for HTTP APIs*) is a good pattern: `type`, `title`, `status`, `detail`, optional `instance`; many teams also use a compact custom JSON with `message` / `errors[]`.

Example (generic validation error shape):

```json
{
  "status": 400,
  "message": "Invalid request body",
  "errors": [
    { "field": "email", "message": "Invalid email address format" },
    { "field": "price", "message": "Price must be a positive number" }
  ]
}
```

## Request body

- **JSON** for request bodies unless the API explicitly supports other media types.
- **POST/PUT** payloads belong in the **body**, not duplicated in query strings.
- **Clear field names**; **meaningful types** (string, number, boolean, array, object).
- **Validate** required fields, formats (email, UUID), min/max length, numeric ranges on the server.
- **Arrays** for homogeneous collections of items.
- **PATCH** for partial updates with only changed fields.
- Prefer **reasonably flat** JSON; avoid deeply nested objects when a flatter or referenced model works.
- **Dates** in **ISO 8601** (`YYYY-MM-DDTHH:MM:SSZ`).

## Anti-patterns

| Anti-pattern | Why it hurts | Prefer |
| ------------ | ------------ | ------ |
| Verbs in URLs (`/getUser`) | Not resource-oriented | `GET /users/{id}` |
| `200` for errors | Breaks client expectations | Matching 4xx/5xx |
| No API versioning | Breaking changes hit all clients | `/v1/` or documented policy |
| Exposing raw DB IDs without care | Enumeration, coupling | Opaque IDs or UUIDs where needed |
| No pagination on large lists | Timeouts, memory | Cursor or page+size |
| GET for mutations | Caching, CSRF, semantics | POST/PUT/PATCH/DELETE |
| Inconsistent error shape | Hard to integrate | One documented error model |
| Missing rate limits | Abuse, DoS | 429 + documented limits |

## Quick troubleshooting

| Symptom | Often caused by | Check |
| ------- | --------------- | ----- |
| 401 | Missing/invalid token | `Authorization` header, clock skew |
| 403 | Auth OK, no permission | Roles, resource ownership |
| 404 | Wrong path or ID | Route registration, soft-delete |
| 409 | Unique constraint, state | Idempotency, conflict handling |
| 422 | Validation | Schema, required fields |
| 429 | Throttling | Backoff, `Retry-After` |
| 500 | Unhandled exception | Logs, sanitize responses |
| CORS | Browser blocked origin | Allowed origins, methods, headers |

## Production readiness (checklist)

- Input validation on **all** mutating endpoints.
- Rate limiting with **429** and documented limits.
- CORS restricted to known origins (for browser clients).
- **API versioning** strategy documented.
- Pagination strategy chosen and documented.
- Consistent **error** format and **request IDs** for support.
- Structured logging; **never** log secrets or full auth headers.
- **Health** endpoint for load balancers where applicable.
- Body size limits and timeouts configured.

## OpenAPI / Swagger

- **Base path** / server URL and **version** visible (e.g. `/api/v1`).
- Each operation: **summary/description**, **parameters** (path, query, header), **request body** schema, **responses** with status codes and **examples**.
- **Security schemes** (Bearer, OAuth2, etc.) declared and applied.
- Use **annotations** or codegen (e.g. Spring, ASP.NET) to keep spec and code aligned when possible.

## Attribution

This reference synthesizes widely used REST practices, ideas aligned with public [rest-api (claude-dev-suite)](https://skills.sh/claude-dev-suite/claude-dev-suite/rest-api) on skills.sh, and common internal guideline patterns (paths, pagination, versioning, errors, OpenAPI). Adapt to your organization’s standards where they differ.
