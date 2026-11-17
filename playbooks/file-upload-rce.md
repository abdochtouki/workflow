# File upload → RCE (and traversal)

In the writeup corpus, RCE is almost always the *top of a chain*, and file
upload / path traversal is one of the most common bottom rungs. CWE-434 /
CWE-22.

## Trigger

Anywhere the app accepts a file or a filename you influence: avatar/image
upload, document import, attachments, export/import, profile backgrounds,
support tickets, "upload from URL" (also an SSRF entry — see `ssrf.md`).

## Method

1. Upload the intended type first to learn the happy path (where it's stored,
   the returned URL, whether it's served back).
2. Test what the server validates and how:
   - Extension handling (double extensions, case, trailing chars/dots/null,
     alternate executable extensions for the stack).
   - Content-type vs real content (polyglot files that are a valid image *and*
     carry code).
   - Where files land and whether that path is web-executable.
3. **Path traversal in the filename** — can you write outside the upload dir
   (into a web root, a config, a startup location)?
4. If a file can be both stored and executed by the server, that's the RCE rung.

## Escalate (see docs/escalation-ladders.md)

- Upload a server-executable file to a web-reachable, executable path → **RCE**.
- Path traversal on write → overwrite config / drop into a web root → RCE.
- Upload-from-URL → **SSRF** (pivot to `ssrf.md`).
- Can't reach RCE? Lower rungs still matter: stored XSS via SVG/HTML upload,
  content-type confusion, overwriting other users' files (IDOR-on-upload).

## Safety

Prove execution with a **benign** marker (print a unique string / echo an
identifier), never a real payload or anything that changes the host. Don't
persist web shells; remove test files. Don't read beyond what proves it.

## False positives

- The file is stored but served with a safe content-type / from a non-executable
  CDN (no execution).
- Validation strips/renames so your extension never executes.
- Traversal is normalized away server-side.

## Proof

The uploaded file, the request that triggers it, and the benign marker executing
server-side (or the file written to a location it shouldn't reach). State the
exact impact and stop.

## Detection rule to save

"Every upload / filename sink → check: can I control extension+content, where it
lands, and whether that location executes? If yes to all three, it's an RCE
rung."
