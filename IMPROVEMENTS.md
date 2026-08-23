# Improvement recommendations — dag-aftenskolen.dk

> Notes for a future work session. This site works and is low-traffic; treat these as
> opt-in improvements, not a mandate. Ordered by value-for-effort. Nothing here is urgent.

## How the site works today (orientation)
- Jekyll 3.8 static site, built in Docker (`build.sh` / `serve.sh`), no Gemfile.
- Deployed to **AWS S3 + CloudFront** via `.github/workflows/ci.yml` on push to `master`
  (same steps as `deploy.sh`). `_site/` is gitignored.
- Content shell lives in `_layouts/default.html`; pages are `index.html`, `tilmelding.html`,
  `kurser.html`, `bestyrelsen.html`, `tak.html`, `persondatapolitik.html`.
- Data-driven bits: `_data/courses.csv` drives both the course cards (`index.html`) and the
  signup checkboxes (`tilmelding.html`). `_data/news.csv` is wired up but hidden (`w3-hide`).
- Each season the editor changes: the `<h2>` season label + header image in `index.html`,
  the "Arrangementer" event card(s) by hand (old ones kept as commented-out blocks), and
  rewrites rows in `courses.csv`.

---

## Tier 1 — Reduce the seasonal editing pain (highest value)

### 1.1 Make the "Arrangementer" (events) section data-driven
**Problem:** Every season the event card in `index.html` (currently ~lines 63–117) is
hand-written HTML, copy-pasted from last season, with the previous card left behind as a
commented-out block (see the `<!-- ... -->` block around lines 65–95). This is the single most
error-prone recurring edit (mismatched tags, wrong Liquid, stale text) and it accumulates cruft.

**Fix:** Mirror the courses pattern. Add `_data/events.yml` and an include
`_includes/event-card.html`, then loop in `index.html`. YAML (not CSV) because event bodies are
multi-paragraph and contain HTML.

```yaml
# _data/events.yml
- title: Årets gang i permakulturhaven
  speaker: Karoline Nolsø Aaen
  date: Torsdag den 22. oktober kl. 19:00
  place: Rønde Bibliotek
  price: 50 kr.
  img: karoline-2026.jpg
  img_alt: Karoline Nolsø Aaen i køkkenhaven
  active: true
  body: >
    Havebrug uden stress. Hvordan skaber man størst mulig selvforsyning fra haven? …
```

```liquid
<!-- index.html, replacing the hand-written card block -->
{% for e in site.data.events %}{% if e.active %}
  {% include event-card.html event=e %}
{% endif %}{% endfor %}
```

`_includes/event-card.html` holds the markup once (title / speaker / date / price / signup link
/ image / body). Old events become `active: false` (kept as data, not commented HTML) or are
deleted — no more commented-out cards in `index.html`.

**Payoff:** Adding next season's talk becomes editing a small YAML block; markup can't break.

### 1.2 Put the season label + header image in one place
**Problem:** Each season you edit the `<h2>Efterårssæson 2026</h2>` label and swap the header
`<img>` (spring `snowdrop.jpg` / `foraar.jpg` ↔ autumn `efteraar.jpg`) inside `index.html`.
Easy to forget one (this exact drift happened: header image was left as spring while the season
had turned to autumn).

**Fix:** Add `_data/site.yml` (or reuse `_config.yml`) and reference it:
```yaml
# _data/site.yml
season: Efterårssæson 2026
header_image: efteraar.jpg
```
```liquid
<h2>{{ site.data.site.season }}</h2>
<img src="{{ '/assets/img/' | append: site.data.site.header_image | relative_url }}" …>
```
Now the season change is two lines in one obvious file.

---

## Tier 2 — Correctness & performance (small, real wins)

### 2.1 Stop defeating the CDN cache
**Problem:** `_layouts/default.html` sends, on every page:
```html
<meta http-equiv="cache-control" content="no-cache"/>
<meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT"/>
<meta http-equiv="pragma" content="no-cache"/>
```
and `deploy.sh` uploads everything with `--cache-control "max-age=0"`. Combined, CloudFront and
browsers cache essentially nothing — every visit re-downloads the logo, CSS, and season images.
For a static site fronted by a CDN this is pure waste.

**Fix:** Remove the three `no-cache`/`expires`/`pragma` meta tags. In `deploy.sh`, cache HTML
briefly and static assets long, e.g. two syncs:
- HTML: `--cache-control "public, max-age=300"` (or `no-cache` if you want instant updates)
- `assets/**` (images, css): `--cache-control "public, max-age=604800"`

CloudFront invalidation on deploy already forces freshness, so long asset TTLs are safe.

### 2.2 Per-page `<title>`
**Problem:** `_layouts/default.html` hardcodes `<title>Dag- og aftenskolen i Rønde</title>`,
even though pages set front-matter `title:` (e.g. `tilmelding.html`, `kurser.html`). Every page
has the same browser/tab/SEO title.

**Fix:**
```liquid
<title>{% if page.title %}{{ page.title }} – {% endif %}{{ site.title }}</title>
```

### 2.3 Optional: pin dependencies / consider Jekyll 4
Jekyll 3.8 (June 2018) is only pinned via the Docker image tag; there's no `Gemfile`. It works
and is reproducible, so this is low priority. If touched: add a `Gemfile` pinning `jekyll` and
`kramdown`/`webrick`, and evaluate a bump to Jekyll 4.x. **Only do this if something forces it** —
otherwise "it works, don't touch it" is the right call for a site this size.

---

## Tier 3 — Accessibility & SEO (quick, polish)

### 3.1 `lang` attribute
`<html>` in `_layouts/default.html` has no `lang`. Add `<html lang="da">`. (The non-standard
`<meta http-equiv="Content-Language">` on line ~17 can then go.)

### 3.2 Image `alt` text
Images lack `alt`: the logo (layout ~line 65), the header season image, event/speaker photos,
course images. Add short Danish `alt` text. For data-driven images (courses, events), add an
`img_alt` field so alt travels with the data.

### 3.3 Open Graph tags for Facebook shares
The site actively uses Facebook (page link, Pixel, newsletter). Shared links currently have no
preview card. Add to `_layouts/default.html`:
```html
<meta property="og:title" content="{{ page.title | default: site.title }}">
<meta property="og:description" content="…">
<meta property="og:image" content="{{ '/assets/img/efteraar.jpg' | absolute_url }}">
<meta property="og:type" content="website">
```

---

## Tier 4 — Housekeeping (nice-to-have, low value)

- **`_includes/` for the repeated shell bits.** The `<div class="w3-col l1"><p></p></div>`
  spacer boilerplate and the blue/green section wrappers repeat across every page. Extracting a
  couple of includes would DRY it up, but the pages are short — low urgency.
- **`kurser.html`** is a meta-refresh redirect to `/#kurser`. Fine; could instead be a
  CloudFront/S3 redirect rule. Minor.
- **`bestyrelsen.html`** is a plain HTML table. Could move board contacts to
  `_data/board.yml` + a loop for consistency with the rest of the site. Minor.
- **`news.csv` + hidden news section** in `index.html` is dead-ish (wrapped in `w3-hide`).
  Either wire it up or delete it to reduce confusion.
- **Review tracking scripts.** Facebook Pixel + Cookiebot + Google Analytics all load on every
  page. Confirm the Pixel is still wanted; if not, removing it trims third-party JS and privacy
  surface. (Cookiebot + `persondatapolitik.html` cover consent, so this is a choice, not a bug.)
- **Image organization.** ~37 flat files in `assets/img/`. Optional: group by season/type. Cosmetic.

---

## Suggested order if implementing later
1. Tier 1.2 (season config) — 15 min, immediate everyday payoff.
2. Tier 1.1 (events → data) — the big one; do it right before/after a season change.
3. Tier 2.1 + 2.2 (caching + title) — quick correctness wins.
4. Tier 3 (a11y/SEO) — quick polish, batch together.
5. Tier 4 — only if bored / while already in a file.

## Verification for any future implementation
- Build locally: `./build.sh` (Docker Jekyll 3.8), confirm no Liquid errors.
- Grep `_site/index.html` for the rendered season label, event title/date, and course rows.
- Check `_site/` still contains referenced images and that pages render the shell.
- For caching changes, after deploy inspect response headers
  (`curl -I https://dag-aftenskolen.dk/assets/img/efteraar.jpg`).
