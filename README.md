<div align="center">
  <img src="https://trenstudio.com/sema/sema.ico" alt="SEMA Logo" width="120" style="margin-bottom: 20px;">
  <h1>.sema Format</h1>
  <p><b>The File That Knows Itself.</b></p>
  <p>A self-describing, zero-API semantic archive format that wraps any content (PDF, Image, Text, Code) into an intelligent `.zip`-compatible bundle.</p>
  
  [![Version](https://img.shields.io/badge/version-1.0.0-00ff88.svg?style=flat-square&logo=git)](https://trenstudio.com/sema/)
  [![License](https://img.shields.io/badge/license-MIT-7c3aed.svg?style=flat-square)](LICENSE)
  [![Platform](https://img.shields.io/badge/platform-Win%20%7C%20Mac%20%7C%20Linux-blue.svg?style=flat-square)](#installation)
  
  <br/>
  <a href="https://trenstudio.com/sema/">Official Website</a> · 
  <a href="https://trenstudio.com/sema/sema-spec.html">Format Specification</a>
</div>

---

## 🔮 What is `.sema`?

Traditional files are "dead" bytes. A `.pdf` requires a PDF reader. A `.docx` requires Word. If you want to know what's inside them, you have to open them or rely on fragile external APIs.

The **`.sema` (Semantic)** format wraps your original file alongside a pre-computed intelligence layer (`brain.json`), file metadata (`sema.json`), and a localized HTML viewer (`view.html`). This makes the file 100% self-sufficient.

An OS equipped with a `.sema` handler can instantly display the file's summary, keywords, language, and core contents *without ever reading or parsing the original binary*.

## 🏗️ The Anatomy of a `.sema` Archive

A `.sema` file is technically a standard ZIP archive (compression level 6). You can rename any `.sema` to `.zip` to inspect it.
```text
your_file.sema/
├── sema.json          # File identity, MIME type, cryptographic checksum
├── brain.json         # Extracted keywords, NLP summaries, translated pairs
├── view.html          # Self-contained Glassmorphism UI to view the file
└── content/           # Your actual original file (e.g., photo.jpg, report.pdf)
```

---

## ⚡ Installation (System Handlers)

To make `.sema` files open natively on your OS by double-clicking:

### Windows (Recommended)
1. Download `install_sema_windows.bat` from the [official site](https://trenstudio.com/sema/).
2. Right-click and choose **Run as Administrator**.
3. Double click any `.sema` file.

### macOS
1. Download `install_sema_macos.sh`.
2. Run via terminal: `chmod +x install_sema_macos.sh && ./install_sema_macos.sh`.
3. Allow `.sema` in Launch Services.

### Linux
1. Download `install_sema_linux.sh`.
2. Run via terminal: `chmod +x install_sema_linux.sh && ./install_sema_linux.sh`.

---

## 🛠️ Building your own `.sema` files

We provide a Python-based intelligent compiler that automatically extracts text, parses PDFs/DOCX, generates summaries (locally via NLP logic), and packages everything.

### 1. Requirements
Install the necessary local extractors:
```bash
pip install -r files/requirements.txt
```

### 2. Usage
Run the CLI tool and point it to any standard file:
```bash
python files/sema_builder.py my_document.pdf --author "John Doe" --org "TREN Studio"
```

The output will be `my_document.sema`, ready to be double-clicked or dragged into the viewer!

---
<div align="center">
  <p>Built with ❤️ by <b>TREN Studio</b> · <a href="https://trenstudio.com">trenstudio.com</a></p>
</div>
