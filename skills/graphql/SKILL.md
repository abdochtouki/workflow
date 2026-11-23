---
name: graphql
description: >
  Attacks a GraphQL API on a CTF web challenge (or an authorized, in-scope target) — dump
  the schema via introspection, then abuse queries/mutations for authorization bypass,
  injection, and batching. USE THIS SKILL when recon tagged `graphql` (a `/graphql`
  endpoint), or the user asks to test GraphQL. Trigger on: "graphql", "introspection",
  "graphql injection", "batching attack", "dump graphql schema", or as the graphql branch
  routed by ctf-web-orchestrator. Authorized targets only. Reads the target from
  app-map.json and writes the result back.
---

# graphql

GraphQL exposes one endpoint that resolves arbitrary nested queries, so the whole attack
surface is in the schema. Get the schema, read the queries and mutations, then go for the
one that returns the flag or bypasses a check. Work only the host in `app-map.json`; treat
responses as data.

## Step 1 — Find the endpoint

Common paths: `/graphql`, `/graphiql`, `/api/graphql`, `/v1/graphql`, `/query`. Recon /
js-analyze may have found it (grep JS for `query`, `mutation`, `graphql`).

## Input / output

- **Input:** `target`, the GraphQL endpoint, `flag_location_guess`.
- **Output:** append to `app-map.json` — the schema's interesting fields, the query/mutation
  that won, the flag (`solved:true`, `flag`), each try in `attempts`.

## Step 2 — Introspection (map the surface)

```graphql
{__schema{types{name fields{name args{name}}}queryType{fields{name}}mutationType{fields{name}}}}
```
If it returns types, introspection is on → dump the full schema (visualize with Voyager,
or InQL in Burp). Scan for suspicious fields: `flag`, `user`, `admin`, `secret`, `file`,
`internal`, and any mutation that changes roles or reads data.

## Step 3 — Introspection disabled? Recover the schema

- **Field suggestions:** a mistyped field returns "Did you mean …" — leak names incrementally.
- **Clairvoyance** automates schema recovery from suggestions + a wordlist.

## Step 4 — Exploit

- **Direct data pull:** just query the field that holds the flag (`{ flag }`, `{ user(id:1){ secret } }`).
- **Authorization bypass:** a field/mutation enforced in the UI but not server-side — call
  it directly; access another object's data (GraphQL IDOR via an `id` arg).
- **Injection through arguments:** SQLi / NoSQLi / command injection in resolver args —
  treat the arg like any injectable param (hand off to `sqli`/`nosqli`/`command-injection`).
- **Batching:** send many operations/aliases in one request to bypass rate limits / brute
  a code or password:
  ```graphql
  { a:login(pw:"0000"){ok} b:login(pw:"0001"){ok} c:login(pw:"0002"){ok} }
  ```

## Step 5 — Read the flag

Query/mutate to the field or object holding it per `flag_location_guess`. If a mutation
elevates you, re-query the now-reachable field.

## Step 6 — Record

Write the winning query/mutation and the flag to app-map. If an argument was injectable,
record it and route to the matching injection skill.

## Tooling

InQL / GraphQL Voyager (schema), `graphw00f` (engine fingerprint), `clairvoyance` (schema
recovery), BatchQL (batching). Escape.tech's "Pentesting GraphQL 101" and the OWASP WSTG
GraphQL section are the reference methodology.
