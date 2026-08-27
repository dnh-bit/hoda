
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, re, json, urllib.request, ssl, html as htmlmod

def fetch(url, timeout=25):
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept-Language": "fa,en;q=0.8",
        "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
    })
    data = urllib.request.urlopen(req, timeout=timeout, context=ctx).read()
    for enc in ("utf-8",):
        try:
            return data.decode(enc, "ignore")
        except Exception:
            pass
    return data.decode("latin-1", "ignore")

def to_text(html):
    html = re.sub(r'<script[\s\S]*?</script>', ' ', html, flags=re.I)
    html = re.sub(r'<style[\s\S]*?</style>', ' ', html, flags=re.I)
    html = re.sub(r'<!--[\s\S]*?-->', ' ', html)
    # keep some structure
    html = re.sub(r'<(br|/p|/div|/li|/h[1-6])[^>]*>', '\n', html, flags=re.I)
    text = re.sub(r'<[^>]+>', ' ', html)
    text = htmlmod.unescape(text)
    text = text.replace('\u200c', '\u200c')
    lines = [re.sub(r'[ \t\u00a0]+', ' ', ln).strip() for ln in text.split('\n')]
    lines = [ln for ln in lines if ln]
    return '\n'.join(lines)

if __name__ == '__main__':
    urls = [u.strip() for u in open("urls_batch1.txt", encoding='utf-8') if u.strip()]
    outdir = sys.argv[2]
    import os
    os.makedirs(outdir, exist_ok=True)
    results = {}
    for u in urls:
        try:
            t = to_text(fetch(u))
            fn = os.path.join(outdir, re.sub(r'\W+', '_', u)[:80] + '.txt')
            with open(fn, 'w', encoding='utf-8') as f:
                f.write("URL: " + u + "\n\n" + t[:60000])
            print("OK", len(t), u)
        except Exception as e:
            print("ERR", str(e)[:120], u)

def extract_will(html):
    """Extract will text from fetched page"""
    text = to_text(html)
    # Find sections mentioning وصیت
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    # look for will-like content: paragraphs with religious/spiritual themes
    will_lines = []
    keywords = ['وصیت', 'شهید', 'خدا', 'امام', 'حسین', 'جهاد', 'شهادت', 'سلام', 'فرزند', 'همسر', 'پدر', 'مادر']
    for i, line in enumerate(lines):
        if any(k in line for k in keywords) and len(line) > 40:
            will_lines.append(line)
    return will_lines[:10]

if __name__ == '__main__':
    import json, os
    urls = [u.strip() for u in open('urls_batch1.txt') if u.strip()]
    results = []
    out_file = 'shohada_raw.json'
    existing = {}
    if os.path.exists(out_file):
        try:
            existing = {e['source_url']: e for e in json.load(open(out_file))}
        except: pass
    for url in urls:
        if url in existing: continue
        try:
            html = fetch(url)
            wills = extract_will(html)
            if wills:
                results.append({
                    'name': 'نامشخص',
                    'year': '',
                    'place': '',
                    'excerpt': ' '.join(wills[:3])[:500],
                    'source_url': url
                })
                print(f'✓ {url[:60]}')
            else:
                print(f'✗ no text {url[:50]}')
        except Exception as e:
            print(f'✗ err {url[:50]}: {e}')
        # small delay
        import time; time.sleep(0.3)
    # merge
    for r in results: existing[r['source_url']] = r
    json.dump(list(existing.values()), open(out_file,'w'), ensure_ascii=False, indent=1)
    print(f'\nTotal: {len(existing)} entries saved')
