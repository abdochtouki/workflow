# SQL Injection (SQLi)

Rarer on modern ORM stacks, but high-value where it survives — raw queries,
legacy endpoints, search, reporting/export, and dynamic `ORDER BY`/filters.
CWE-89.

## Trigger

Any parameter that reaches a query: search, filters, sort columns, IDs in raw
queries, `LIMIT`/`OFFSET`, export/report builders, legacy or internal endpoints,
GraphQL resolvers over raw SQL.

## Method

1. Baseline the normal response for the parameter.
2. Probe for a difference, safest first:
   - **Error-based**: does a syntax-breaking character change the response or
     surface a DB error?
   - **Boolean/blind**: a true vs false condition produces different responses.
   - **Time-based**: a conditional delay changes response time (confirm with
     several trials; watch for network noise).
   - **`ORDER BY` / column context**: injection points that aren't in a `WHERE`.
3. Confirm it's really the DB (not caching, rate-limiting, or app logic) with a
   controlled true/false pair.
4. Use PayloadsAllTheThings / the DB-specific cheatsheet for syntax; prefer a
   manual confirmation before any tooling.

## Impact & escalation

- Read data you shouldn't (another tenant's rows) → data breach.
- Auth bypass via injectable login.
- In some stacks, stacked queries / file write → **RCE** (top of the ladder).
- Keep the proof minimal — demonstrate the injection and *one* row of impact,
  never dump the database.

## Safety

- **Never run mass extraction or destructive queries.** No `DROP`, no `UPDATE`/
  `DELETE`, no bulk dumps. Prove the vulnerability, not the blast radius.
- Time-based tests cause load — keep them small, respect 429.
- Don't point `sqlmap` at a live target and submit its output verbatim
  (never-submit: scanner dumps).

## False positives

- A WAF/error page that changes on any odd input, not specifically on SQL syntax.
- Response differences caused by caching or app validation, not the DB.
- A "DB error" that's actually a generic 500.

## Proof

The minimal request pair proving injection (boolean true vs false, or a
controlled error/delay), plus one piece of impact (a value you shouldn't be able
to read). State the DBMS and injection type.

## Detection rule to save

"Any parameter reaching a query (incl. sort/filter/export) → test a controlled
true/false pair; confirm it's the DB before escalating, and never dump."
