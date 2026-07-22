# 0008. Rails JSON API + React SPA, single-origin deploy

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The goal is a Rails + PostgreSQL backend with a well-thought UX, without excessive
styling or over-engineering. Rails + React is a mainstream, well-supported pairing.

## Decision

A **Rails 8 API-only** backend (`--api`) plus a **React + Vite + TypeScript SPA**
(`client/`) using TanStack Query, React Router, and Tailwind. In **dev**, Vite proxies
`/api` to Rails (no CORS); in **prod**, the Dockerfile builds the SPA into Rails
`public/`, so it ships as **one origin, one artifact, one deploy**.

## Alternatives considered

- **Hotwire / server-rendered ERB** — simpler for a backend dev, but doesn't show
  full-stack range.
- **Separate FE/BE hosting** (e.g. Vercel + Fly) — two deploys, CORS, more surface to
  defend for no benefit at this size.

## Consequences

- Demonstrates full-stack range; single-origin keeps
  deployment and security simple (no CORS).
- Pantry state lives in `localStorage` — no accounts, which suits the "what's in my
  kitchen right now" framing.
- **Trade-off:** an SPA is more moving parts than Hotwire would be. Kept deliberately
  lean (minimal styling) so it doesn't read as over-engineering.
