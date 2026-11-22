#!/usr/bin/env python3
"""Turn `jsluice urls` JSONL into deduped curl commands + endpoint/param lists.
usage: jsluice2curl.py urls.jsonl https://base.target.com [outdir]"""
import json, sys, shlex, os
from urllib.parse import urljoin, urlencode, urlsplit, parse_qsl
src, base = sys.argv[1], sys.argv[2].rstrip('/') + '/'
out = sys.argv[3] if len(sys.argv) > 3 else '.'
os.makedirs(out, exist_ok=True)
seen, curls, eps, params = set(), [], set(), set()
for line in open(src, errors='ignore'):
    try: r = json.loads(line)
    except Exception: continue
    u = (r.get('url') or '').strip()
    if not u or u.startswith(('data:', 'mailto:', 'javascript:', 'blob:')): continue
    full = urljoin(base, u.lstrip('./') if not u.startswith(('http', '/')) else u)
    m = (r.get('method') or 'GET').upper()
    sp = urlsplit(full)
    qp = list(r.get('queryParams') or []) + [k for k, _ in parse_qsl(sp.query)]
    bp = list(r.get('bodyParams') or [])
    key = (m, sp.scheme + '://' + sp.netloc + sp.path)
    if key in seen: continue
    seen.add(key); eps.add(key[1]); params.update(qp + bp)
    url = key[1] + ('?' + urlencode({p: 'FUZZ' for p in dict.fromkeys(qp)}) if qp else '')
    cmd = ['curl', '-sk', '-X', m, url, '-H', 'Authorization: Bearer $TOKEN']
    for h, v in (r.get('headers') or {}).items():
        cmd += ['-H', f'{h}: {v}']
    if bp and m != 'GET':
        cmd += ['-H', 'Content-Type: application/json', '--data',
                json.dumps({p: 'FUZZ' for p in dict.fromkeys(bp)})]
    curls.append(f"# {r.get('filename','?')}\n" + ' '.join(shlex.quote(c) if '$TOKEN' not in c else '"' + c + '"' for c in cmd))
open(f'{out}/curl_commands.sh', 'w').write('#!/usr/bin/env bash\n# export TOKEN=... first\n' + '\n'.join(curls) + '\n')
open(f'{out}/endpoints.txt', 'w').write('\n'.join(sorted(eps)) + '\n')
open(f'{out}/params.txt', 'w').write('\n'.join(sorted(p for p in params if p)) + '\n')
print(f'[+] {len(curls)} requests, {len(eps)} endpoints, {len(params)} params -> {out}')
