# Pigeon: EBook Sender

A script to send ebook to kindle via email in one go

> **⚠️ DEPRECATED**: This project works but is painfully slow due to SMTP limitations. So BYE

## What is this?

Initially I'm tired of downloading ebooks and sending them to Kindle via email. Too much drag and drop. I wanted a script to automate it. It's doing the work, but unfortunately later I realized using SMTP protocol to send attachments is a horrible idea. A 500KB file needs 2-5 minutes to transfer which throws me back to the Jurassic. Anyway, it's always fun learning something new and it was a well-spent 2 hours. I might refactor it to Gmail API later if I feel like it. But for now, this is deprecated.

## Features

- ✅ Send ebooks (.epub, .pdf, .mobi, .txt) to Kindle via email
- ✅ Support for Gmail App Password authentication
- ✅ Right-click menu integration on macOS
- ✅ File size validation (35MB Gmail limit)
- ✅ Colorful terminal output with progress info
- ✅ Health checks for configuration
- 🐌 Extremely slow due to SMTP protocol limitations

## How it works

1. **Authentication**: Uses Gmail App Password with SMTP over SSL
2. **File Processing**: Encodes files to base64 and wraps in MIME format
3. **Transmission**: Sends via `curl` to `smtp.gmail.com:465` using raw SMTP
4. **Integration**: Can be triggered via command line or macOS right-click menu

## Usage

```bash
# Send single file
./send_ebook.sh book.epub

# Send multiple files
./send_ebook.sh *.pdf

# Send latest ebook in current directory
./send_ebook.sh

# Right-click any ebook file → "Send to Kindle"
```

## Lessons Learned

1. SMTP wasn't designed for file attachments
2. Gmail's web interface uses optimized APIs, not raw SMTP. But yeah curl uses the raw SMTP
3. Sometimes the "simple" solution is actually the complicated one
4. Modern email clients hide the underlying protocol complexity for good reason

---

_"It works, but at what cost?" - Ancient developer proverb_
