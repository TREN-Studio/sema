#!/usr/bin/env python3
"""
.sema CLI Builder v1.0
Converts any file into a self-describing .sema archive.
No API. No internet. Pure local intelligence.

Authors: Larbi + Claude | TREN Studio
License: MIT
"""

import os
import sys
import json
import uuid
import zipfile
import hashlib
import argparse
import re
from datetime import datetime, timezone
from pathlib import Path
from collections import Counter

# ─────────────────────────────────────────────
# CONTENT EXTRACTORS
# ─────────────────────────────────────────────

def extract_text_from_pdf(path):
    try:
        import fitz
        doc = fitz.open(path)
        text = ""
        for page in doc:
            text += page.get_text()
        doc.close()
        return text.strip()
    except Exception as e:
        return f"[PDF extraction error: {e}]"


def extract_text_from_docx(path):
    try:
        from docx import Document
        doc = Document(path)
        return "\n".join([p.text for p in doc.paragraphs if p.text.strip()])
    except Exception as e:
        return f"[DOCX extraction error: {e}]"


def extract_text_from_txt(path):
    try:
        import chardet
        with open(path, 'rb') as f:
            raw = f.read()
        enc = chardet.detect(raw).get('encoding', 'utf-8') or 'utf-8'
        return raw.decode(enc, errors='replace')
    except Exception as e:
        return f"[TXT extraction error: {e}]"


def extract_text_from_image(path):
    try:
        from PIL import Image
        img = Image.open(path)
        info = {
            "format": img.format,
            "mode": img.mode,
            "size": f"{img.width}x{img.height}",
            "width": img.width,
            "height": img.height,
        }
        # Try EXIF
        exif_data = {}
        try:
            exif = img._getexif()
            if exif:
                from PIL.ExifTags import TAGS
                for tag_id, value in exif.items():
                    tag = TAGS.get(tag_id, tag_id)
                    if isinstance(value, (str, int, float)):
                        exif_data[str(tag)] = str(value)
        except:
            pass
        info["exif"] = exif_data
        return json.dumps(info)
    except Exception as e:
        return f"[Image extraction error: {e}]"


def extract_text_from_xlsx(path):
    try:
        import openpyxl
        wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
        texts = []
        for ws in wb.worksheets:
            texts.append(f"Sheet: {ws.title}")
            for row in ws.iter_rows(max_row=200, values_only=True):
                row_text = " | ".join(str(c) for c in row if c is not None)
                if row_text.strip():
                    texts.append(row_text)
        return "\n".join(texts)
    except Exception as e:
        return f"[XLSX extraction error: {e}]"


def extract_text(file_path):
    ext = Path(file_path).suffix.lower()
    if ext == '.pdf':
        return extract_text_from_pdf(file_path)
    elif ext in ['.docx']:
        return extract_text_from_docx(file_path)
    elif ext in ['.txt', '.md', '.csv', '.json', '.html', '.xml', '.py', '.js']:
        return extract_text_from_txt(file_path)
    elif ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff']:
        return extract_text_from_image(file_path)
    elif ext in ['.xlsx', '.xls']:
        return extract_text_from_xlsx(file_path)
    else:
        return f"[No text extractor for {ext}]"


# ─────────────────────────────────────────────
# LOCAL BRAIN ENGINE (Zero API)
# ─────────────────────────────────────────────

# Arabic stop words
STOPWORDS_AR = set([
    "في","من","إلى","على","عن","مع","هذا","هذه","التي","الذي","كان","كانت",
    "أن","إن","وأن","ولا","وهو","وهي","هو","هي","أو","لا","ما","كل","قد",
    "لم","لن","ثم","حتى","بعد","قبل","عند","منذ","خلال","بين","بعض","كيف",
    "لقد","إذا","لكن","ولكن","حين","أيضاً","أيضا","فقط","وقد","وكان","وهذا"
])

# English stop words  
STOPWORDS_EN = set([
    "the","a","an","and","or","but","in","on","at","to","for","of","with",
    "by","from","is","are","was","were","be","been","have","has","had",
    "do","does","did","will","would","could","should","may","might","it",
    "its","this","that","these","those","he","she","they","we","you","i",
    "not","no","nor","so","yet","both","either","just","than","then","when",
    "where","who","which","what","how","if","as","up","out","about","into"
])


def clean_and_tokenize(text):
    """Extract meaningful tokens from text."""
    text = re.sub(r'[^\w\s\u0600-\u06FF]', ' ', text)
    tokens = text.lower().split()
    tokens = [t for t in tokens if len(t) > 3]
    tokens = [t for t in tokens if t not in STOPWORDS_EN and t not in STOPWORDS_AR]
    return tokens


def extract_keywords(text, top_n=20):
    """Extract top keywords by frequency."""
    tokens = clean_and_tokenize(text)
    freq = Counter(tokens)
    return [word for word, _ in freq.most_common(top_n)]


def detect_language(text):
    """Simple language detection."""
    arabic_chars = len(re.findall(r'[\u0600-\u06FF]', text))
    latin_chars = len(re.findall(r'[a-zA-Z]', text))
    french_indicators = ['le ', 'la ', 'les ', 'de ', 'du ', 'des ', 'et ', 'est ', 'une ', 'un ']
    french_count = sum(1 for f in french_indicators if f in text.lower())

    if arabic_chars > latin_chars:
        return "ar"
    elif french_count > 3:
        return "fr"
    else:
        return "en"


def generate_summary(text, sentences=3):
    """Extract most representative sentences as summary."""
    # Split into sentences
    sent_pattern = r'(?<=[.!?؟])\s+|(?<=[.!?؟])$'
    sentences_list = re.split(sent_pattern, text.strip())
    sentences_list = [s.strip() for s in sentences_list if len(s.strip()) > 30]

    if not sentences_list:
        # Fallback: take first N words
        words = text.split()[:60]
        return ' '.join(words) + '...'

    # Score sentences by keyword density
    all_tokens = clean_and_tokenize(text)
    freq = Counter(all_tokens)

    def score_sentence(s):
        tokens = clean_and_tokenize(s)
        return sum(freq.get(t, 0) for t in tokens) / (len(tokens) + 1)

    scored = sorted(sentences_list, key=score_sentence, reverse=True)
    top = scored[:sentences]

    # Re-order by original position
    result = []
    for s in sentences_list:
        if s in top:
            result.append(s)
        if len(result) == sentences:
            break

    return ' '.join(result) if result else sentences_list[0][:200] + '...'


def detect_content_type(file_path, text):
    """Guess content type from extension and content."""
    ext = Path(file_path).suffix.lower()
    fname = Path(file_path).name.lower()
    text_lower = (text or '').lower()

    # By extension
    if ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']:
        return "image/photo"
    if ext in ['.xlsx', '.xls', '.csv']:
        return "data/spreadsheet"
    if ext in ['.mp3', '.wav', '.ogg', '.m4a']:
        return "media/audio"
    if ext in ['.mp4', '.avi', '.mov', '.mkv']:
        return "media/video"

    # By content keywords
    recipe_words = ['ingredients', 'recipe', 'tablespoon', 'cup', 'cook', 'bake',
                    'وصفة', 'مقادير', 'طريقة', 'دقيقة', 'غرام', 'recette', 'ingrédients']
    invoice_words = ['invoice', 'total', 'amount', 'payment', 'due', 'فاتورة', 'مبلغ']
    contract_words = ['agreement', 'contract', 'party', 'clause', 'عقد', 'اتفاقية']

    recipe_score = sum(1 for w in recipe_words if w in text_lower)
    invoice_score = sum(1 for w in invoice_words if w in text_lower)
    contract_score = sum(1 for w in contract_words if w in text_lower)

    if recipe_score >= 3:
        return "document/recipe"
    if invoice_score >= 2:
        return "document/invoice"
    if contract_score >= 2:
        return "document/contract"

    return "document/generic"


def extract_entities(text):
    """Simple named entity detection using patterns."""
    entities = {"people": [], "places": [], "concepts": [], "dates": []}

    # Dates
    date_patterns = [
        r'\b\d{4}-\d{2}-\d{2}\b',
        r'\b\d{1,2}/\d{1,2}/\d{2,4}\b',
        r'\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}\b',
    ]
    for pattern in date_patterns:
        found = re.findall(pattern, text, re.IGNORECASE)
        entities["dates"].extend(found[:5])

    # Places (capitalized words after location prepositions)
    place_patterns = [
        r'(?:in|at|from|to|near|المغرب|مراكش|الرباط|فاس|طنجة|Morocco|Marrakech|Rabat|Fes)\s+([A-Z][a-z]+)',
    ]
    for pattern in place_patterns:
        found = re.findall(pattern, text)
        entities["places"].extend(found[:5])

    # Remove duplicates
    for k in entities:
        entities[k] = list(dict.fromkeys(entities[k]))[:5]

    return entities


def generate_content_data(content_type, text):
    """Generate content-type-specific structured data."""
    data = {}

    if content_type == "document/recipe":
        # Extract ingredients hints
        lines = text.split('\n')
        ingredient_lines = []
        for line in lines:
            if any(unit in line.lower() for unit in ['cup', 'tbsp', 'tsp', 'gram', 'kg', 'g ',
                                                       'كوب', 'ملعقة', 'غرام', 'كيلو']):
                ingredient_lines.append(line.strip())
        data["ingredients_hints"] = ingredient_lines[:10]

        # Try to find cooking time
        time_match = re.search(r'(\d+)\s*(?:minutes?|mins?|دقيقة|دقائق)', text, re.IGNORECASE)
        if time_match:
            data["cook_time_minutes"] = int(time_match.group(1))

        word_count = len(text.split())
        data["estimated_steps"] = max(1, word_count // 80)

    elif content_type == "image/photo":
        try:
            img_data = json.loads(text)
            data = img_data
        except:
            data["note"] = "Image file"

    elif content_type == "data/spreadsheet":
        lines = text.split('\n')
        data["estimated_rows"] = len([l for l in lines if '|' in l])
        data["sheets"] = [l.replace('Sheet:', '').strip() for l in lines if l.startswith('Sheet:')]

    elif content_type == "document/generic":
        words = text.split()
        data["word_count"] = len(words)
        data["reading_time_minutes"] = max(1, len(words) // 200)
        headings = re.findall(r'^#{1,3}\s+(.+)$', text, re.MULTILINE)
        data["headings"] = headings[:10]

    return data


def generate_questions(text, content_type, summary, keywords):
    """Pre-generate Q&A pairs for instant answering."""
    questions = [
        {"q": "What is this file about?", "a": summary},
        {"q": "What are the main topics?", "a": ", ".join(keywords[:8])},
    ]

    if content_type == "document/recipe":
        questions.extend([
            {"q": "What kind of file is this?", "a": "This is a recipe document."},
            {"q": "ما هذا الملف؟", "a": "هذا ملف وصفة طبخ."},
        ])
    elif content_type == "image/photo":
        try:
            img_data = json.loads(text)
            questions.append({
                "q": "What are the image dimensions?",
                "a": img_data.get("size", "Unknown")
            })
        except:
            pass
    elif content_type == "document/invoice":
        questions.append({
            "q": "What type of document is this?",
            "a": "This is a financial invoice or bill."
        })

    # Add language-specific question
    lang = detect_language(text)
    if lang == "ar":
        questions.append({"q": "ما هي الكلمات الرئيسية؟", "a": "، ".join(keywords[:8])})
    elif lang == "fr":
        questions.append({"q": "De quoi parle ce fichier?", "a": summary[:200]})

    return questions


# ─────────────────────────────────────────────
# VIEW.HTML GENERATOR
# ─────────────────────────────────────────────

def generate_view_html(manifest, brain, original_filename):
    """Generate a self-contained viewer HTML."""
    title = manifest.get("title", original_filename)
    author = manifest.get("author", {}).get("name", "Unknown")
    org = manifest.get("author", {}).get("org", "")
    content_type = manifest.get("content_type", "document/generic")
    created = manifest.get("created_at", "")[:10]
    summary = brain.get("summary", "")
    keywords = brain.get("keywords", [])[:12]
    questions = brain.get("questions", [])
    lang = manifest.get("lang", "en")
    sema_id = manifest.get("id", "")

    # Serialize Q&A for JS
    qa_json = json.dumps(questions, ensure_ascii=False)
    keywords_json = json.dumps(keywords, ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title} — .sema</title>
<style>
  :root {{
    --bg: #0d1117; --surface: #161b22; --border: #30363d;
    --accent: #00ff88; --text: #e6edf3; --muted: #8b949e;
    --accent2: #7c3aed; --warn: #ff6b35;
  }}
  * {{ margin:0; padding:0; box-sizing:border-box; }}
  body {{ background:var(--bg); color:var(--text); font-family: system-ui, -apple-system, sans-serif; min-height:100vh; }}
  header {{ background:var(--surface); border-bottom:1px solid var(--border); padding:20px 24px; display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; }}
  .file-info {{ display:flex; flex-direction:column; gap:4px; }}
  .file-title {{ font-size:18px; font-weight:700; }}
  .file-meta {{ font-size:12px; color:var(--muted); }}
  .sema-badge {{ background:var(--accent); color:#000; font-size:11px; font-weight:800; padding:4px 10px; letter-spacing:1px; border-radius:3px; white-space:nowrap; }}
  main {{ max-width:860px; margin:0 auto; padding:24px; display:grid; gap:20px; }}
  .card {{ background:var(--surface); border:1px solid var(--border); border-radius:6px; padding:20px; }}
  .card-label {{ font-size:10px; letter-spacing:2px; text-transform:uppercase; color:var(--accent); margin-bottom:12px; font-weight:700; }}
  .summary-text {{ font-size:15px; color:var(--text); line-height:1.7; }}
  .keywords {{ display:flex; flex-wrap:wrap; gap:8px; margin-top:8px; }}
  .kw-tag {{ background:var(--bg); border:1px solid var(--border); padding:4px 10px; font-size:12px; border-radius:20px; color:var(--muted); }}
  .ask-bar {{ display:flex; gap:10px; }}
  #question {{ flex:1; background:var(--bg); border:1px solid var(--border); color:var(--text); padding:10px 14px; font-size:14px; border-radius:4px; outline:none; }}
  #question:focus {{ border-color:var(--accent); }}
  #ask-btn {{ background:var(--accent); color:#000; font-weight:700; border:none; padding:10px 20px; cursor:pointer; border-radius:4px; font-size:14px; white-space:nowrap; }}
  #ask-btn:hover {{ opacity:0.85; }}
  #answer {{ margin-top:14px; min-height:40px; padding:12px 14px; background:var(--bg); border-radius:4px; font-size:14px; line-height:1.6; color:var(--text); display:none; }}
  #answer.show {{ display:block; border-left:3px solid var(--accent); }}
  .meta-grid {{ display:grid; grid-template-columns:repeat(auto-fill, minmax(180px, 1fr)); gap:14px; }}
  .meta-item {{ display:flex; flex-direction:column; gap:3px; }}
  .meta-key {{ font-size:10px; color:var(--muted); letter-spacing:1px; text-transform:uppercase; }}
  .meta-val {{ font-size:13px; font-weight:600; color:var(--text); word-break:break-all; }}
  .content-area {{ font-family:monospace; font-size:12px; background:var(--bg); border-radius:4px; padding:14px; max-height:260px; overflow-y:auto; color:var(--muted); line-height:1.6; white-space:pre-wrap; word-break:break-word; }}
  .type-badge {{ display:inline-block; background:var(--accent2); color:#fff; font-size:10px; padding:2px 8px; border-radius:2px; letter-spacing:1px; }}
  footer {{ text-align:center; padding:20px; color:var(--muted); font-size:11px; border-top:1px solid var(--border); margin-top:20px; }}
</style>
</head>
<body>
<header>
  <div class="file-info">
    <div class="file-title">{title}</div>
    <div class="file-meta">
      <span class="type-badge">{content_type}</span>
      &nbsp; By {author}{(' · ' + org) if org else ''} &nbsp;·&nbsp; {created}
    </div>
  </div>
  <div class="sema-badge">.sema v1.0</div>
</header>

<main>

  <!-- SUMMARY -->
  <div class="card">
    <div class="card-label">📋 Summary</div>
    <div class="summary-text">{summary}</div>
    <div class="keywords" id="keywords-container"></div>
  </div>

  <!-- ASK THE FILE -->
  <div class="card">
    <div class="card-label">💬 Ask This File</div>
    <div class="ask-bar">
      <input type="text" id="question" placeholder="Ask anything about this file..." autocomplete="off">
      <button id="ask-btn" onclick="askFile()">Ask →</button>
    </div>
    <div id="answer"></div>
  </div>

  <!-- METADATA -->
  <div class="card">
    <div class="card-label">📌 Metadata</div>
    <div class="meta-grid">
      <div class="meta-item"><span class="meta-key">File</span><span class="meta-val">{original_filename}</span></div>
      <div class="meta-item"><span class="meta-key">Type</span><span class="meta-val">{content_type}</span></div>
      <div class="meta-item"><span class="meta-key">Created</span><span class="meta-val">{created}</span></div>
      <div class="meta-item"><span class="meta-key">Author</span><span class="meta-val">{author}</span></div>
      <div class="meta-item"><span class="meta-key">Language</span><span class="meta-val">{lang}</span></div>
      <div class="meta-item"><span class="meta-key">Sema ID</span><span class="meta-val">{sema_id[:20]}...</span></div>
    </div>
  </div>

  <!-- CONTENT PREVIEW -->
  <div class="card">
    <div class="card-label">📄 Content Preview</div>
    <div class="content-area" id="preview-area">Loading preview...</div>
  </div>

</main>

<footer>.sema Semantic File Format v1.0 · Built by TREN Studio · Open Standard · MIT License</footer>

<script>
const QA = {qa_json};
const KEYWORDS = {keywords_json};
const SEARCH_TEXT = {json.dumps(brain.get("search_text", "")[:3000], ensure_ascii=False)};

// Render keywords
const kc = document.getElementById('keywords-container');
KEYWORDS.forEach(kw => {{
  const span = document.createElement('span');
  span.className = 'kw-tag';
  span.textContent = kw;
  kc.appendChild(span);
}});

// Preview
document.getElementById('preview-area').textContent = 
  SEARCH_TEXT ? SEARCH_TEXT.substring(0, 800) + (SEARCH_TEXT.length > 800 ? '\\n...': '') 
              : 'No text preview available for this file type.';

// Ask the file
function askFile() {{
  const q = document.getElementById('question').value.trim();
  if (!q) return;

  const answerEl = document.getElementById('answer');
  answerEl.className = '';
  answerEl.textContent = '...';

  // 1. Search pre-computed Q&A
  const qLower = q.toLowerCase();
  for (const pair of QA) {{
    const pairQ = pair.q.toLowerCase();
    const words = qLower.split(' ').filter(w => w.length > 3);
    const matches = words.filter(w => pairQ.includes(w));
    if (matches.length >= 1 && matches.length / words.length > 0.4) {{
      answerEl.textContent = pair.a;
      answerEl.className = 'show';
      return;
    }}
  }}

  // 2. Keyword search in full text
  const searchWords = qLower.split(' ').filter(w => w.length > 3);
  const textLower = SEARCH_TEXT.toLowerCase();

  let bestSnippet = '';
  let bestScore = 0;

  const sentences = SEARCH_TEXT.split(/[.!?؟\\n]/).filter(s => s.trim().length > 20);
  for (const s of sentences) {{
    const sLower = s.toLowerCase();
    const score = searchWords.filter(w => sLower.includes(w)).length;
    if (score > bestScore) {{
      bestScore = score;
      bestSnippet = s.trim();
    }}
  }}

  if (bestSnippet && bestScore > 0) {{
    answerEl.textContent = bestSnippet;
  }} else {{
    answerEl.textContent = "I couldn't find a specific answer. Try rephrasing your question or check the content preview above.";
  }}
  answerEl.className = 'show';
}}

document.getElementById('question').addEventListener('keydown', e => {{
  if (e.key === 'Enter') askFile();
}});
</script>
</body>
</html>'''
    return html


# ─────────────────────────────────────────────
# MAIN BUILDER
# ─────────────────────────────────────────────

def build_sema(input_path, output_path=None, author_name="Unknown", author_org="", title=None, verbose=True):
    """Main function: converts a file to .sema format."""

    input_path = Path(input_path)
    if not input_path.exists():
        print(f"[ERROR] File not found: {input_path}")
        return False

    if not output_path:
        output_path = input_path.with_suffix('.sema')
    output_path = Path(output_path)

    if verbose:
        print(f"\n{'─'*50}")
        print(f"  .sema Builder v1.0 — TREN Studio")
        print(f"{'─'*50}")
        print(f"  Input:  {input_path.name}")
        print(f"  Output: {output_path.name}")
        print(f"{'─'*50}\n")

    # 1. Compute checksum
    if verbose: print("  [1/6] Computing checksum...")
    sha256 = hashlib.sha256()
    with open(input_path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            sha256.update(chunk)
    checksum = sha256.hexdigest()

    # 2. Extract text
    if verbose: print("  [2/6] Extracting content...")
    text = extract_text(input_path)

    # 3. Analyze content
    if verbose: print("  [3/6] Analyzing semantics...")
    lang = detect_language(text)
    content_type = detect_content_type(input_path, text)
    keywords = extract_keywords(text, top_n=20)
    summary = generate_summary(text, sentences=3)
    entities = extract_entities(text)
    content_data = generate_content_data(content_type, text)
    questions = generate_questions(text, content_type, summary, keywords)

    # 4. Build sema.json
    if verbose: print("  [4/6] Building manifest...")
    file_title = title or input_path.stem.replace('-', ' ').replace('_', ' ').title()
    sema_id = f"sema_{uuid.uuid4()}"
    created_at = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

    # Detect MIME type
    mime_map = {
        '.pdf': 'application/pdf', '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
        '.txt': 'text/plain', '.md': 'text/markdown', '.html': 'text/html',
        '.mp3': 'audio/mpeg', '.mp4': 'video/mp4',
    }
    mime_type = mime_map.get(input_path.suffix.lower(), 'application/octet-stream')

    manifest = {
        "sema_version": "1.0.0",
        "id": sema_id,
        "created_at": created_at,
        "content_type": content_type,
        "mime_type": mime_type,
        "filename": input_path.name,
        "lang": lang,
        "title": file_title,
        "description": summary[:200] if summary else "",
        "tags": keywords[:8],
        "author": {
            "name": author_name,
            "org": author_org,
            "contact": ""
        },
        "checksum": {
            "algo": "sha256",
            "value": checksum
        },
        "content_size_bytes": input_path.stat().st_size,
        "expires_at": None,
        "geo": {},
        "relations": [],
        "custom": {}
    }

    # 5. Build brain.json
    brain = {
        "brain_version": "1.0",
        "generated_at": created_at,
        "generator": "sema-builder-cli/1.0-local",
        "summary": summary,
        "keywords": keywords,
        "entities": entities,
        "topics": keywords[:6],
        "content_data": content_data,
        "search_text": text[:10000],
        "questions": questions,
        "alt_text": summary[:150] if summary else file_title,
        "translations": {}
    }

    # 6. Generate view.html
    if verbose: print("  [5/6] Generating viewer...")
    view_html = generate_view_html(manifest, brain, input_path.name)

    # 7. Package everything into ZIP (.sema)
    if verbose: print("  [6/6] Packaging .sema archive...")
    with zipfile.ZipFile(output_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        zf.writestr('sema.json', json.dumps(manifest, ensure_ascii=False, indent=2))
        zf.writestr('brain.json', json.dumps(brain, ensure_ascii=False, indent=2))
        zf.writestr('view.html', view_html)
        zf.write(input_path, f'content/{input_path.name}')

    if verbose:
        size_kb = output_path.stat().st_size / 1024
        print(f"\n{'─'*50}")
        print(f"  ✓ Done! Output: {output_path.name} ({size_kb:.1f} KB)")
        print(f"  ✓ Content type: {content_type}")
        print(f"  ✓ Language: {lang}")
        print(f"  ✓ Keywords: {', '.join(keywords[:5])}...")
        print(f"  ✓ Q&A pairs: {len(questions)}")
        print(f"{'─'*50}\n")
        print(f"  Open view.html from the .sema archive in any browser.")
        print(f"  (Rename .sema to .zip and extract to see all layers)\n")

    return str(output_path)


# ─────────────────────────────────────────────
# CLI ENTRY POINT
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='.sema Builder — Convert any file to a self-describing semantic archive',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python sema_builder.py recipe.pdf
  python sema_builder.py photo.jpg -a "Larbi" -o "TREN Studio"
  python sema_builder.py document.docx --title "My Document" --output custom.sema
        """
    )
    parser.add_argument('input', help='Input file to convert')
    parser.add_argument('-o', '--output', help='Output .sema file path (optional)')
    parser.add_argument('-a', '--author', default='Unknown', help='Author name')
    parser.add_argument('--org', default='', help='Organization name')
    parser.add_argument('--title', default=None, help='File title override')
    parser.add_argument('--quiet', action='store_true', help='Suppress output')

    args = parser.parse_args()
    result = build_sema(
        input_path=args.input,
        output_path=args.output,
        author_name=args.author,
        author_org=args.org,
        title=args.title,
        verbose=not args.quiet
    )
    sys.exit(0 if result else 1)


if __name__ == '__main__':
    main()
