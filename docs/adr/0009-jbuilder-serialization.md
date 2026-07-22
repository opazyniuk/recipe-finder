# 0009. jbuilder views for JSON serialization

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The API returns shaped JSON (search buckets with per-recipe fields, ingredient lists).
That shape needs a home that keeps controllers thin and isn't scattered as inline hashes.

## Decision

Render all API responses with **jbuilder views** (`app/views/api/v1/**/*.json.jbuilder`,
with partials like `_match`, `_ingredient`). The JSON shape lives in the view layer;
controllers stay params → service → view. In the API-only app, `BaseController` forces
`request.format = :json` via a `before_action` so the `*.json.jbuilder` templates resolve
without relying on an `Accept` header (Rails 8's `ActionController::API` includes
`ApiRendering`, which provides the view layer).

## Alternatives considered

- **Alba serializers** — started here, then migrated; jbuilder is the Rails default and
  keeps the shape as templates rather than serializer classes.
- **Plain Ruby hashes in controllers** — leaks the response shape into business logic and
  fattens controllers.

## Consequences

- Clear separation: *controllers do HTTP, services do work, views do shape.*
- One small `--api` nuance to remember and explain (the forced `:json` format).
- **Trade-off:** jbuilder is interpreted per-request; negligible here, and the shapes are
  small.
