# Prompt: iLove PDF Clone – Ruby on Rails (Demo + Real Product)

## Context
I'm building a web app for former iLovePDF users (the service shut down). I need:
1. A **functional and reliable** app to give that community a real solution
2. A **solid Rails technical demo** — I'm being asked for Rails knowledge for a job application, so this project also serves as a portfolio piece

**Audience:** Friends + former iLovePDF users. Priority: **minimal friction to use.**

---

## Tech Stack

- **Backend:** Ruby on Rails 7+ (full-stack, no separate API)
- **Frontend:** Hotwire (Turbo + Stimulus) — SPA-like without needing React
- **Styling:** Tailwind CSS
- **PDF Manipulation:** 
  - `hexapdf` or `combine_pdf` (merge, split, rotate, watermark)
  - `pdf-forms` or shell out to `qpdf` (protect/unlock)
- **Office → PDF Conversion:** `libreoffice-convert` gem or shell out to `soffice --headless` (LibreOffice installed on server/container)
- **OCR:** `rtesseract` gem (Tesseract OCR wrapper, runs server-side)
- **Auth:** Devise (optional — see Auth Model section)
- **Background Jobs:** Sidekiq + Redis (for heavy OCR/conversion jobs that must not block the request)
- **Storage:** ActiveStorage with local disk (dev) → Render Disk or S3-compatible (prod)
- **Database:** PostgreSQL (Render offers it managed)
- **Hosting:** Render (Web Service + Background Worker + PostgreSQL)
- **Containerization:** Custom Dockerfile to include LibreOffice + Tesseract binaries

---

## Auth Model (CRITICAL — Minimal Friction)

**Two usage modes, same feature flow:**

1. **Guest Mode (default, no login):**
   - User uploads PDF, processes it, downloads — **no account required**
   - Files are auto-deleted after download or after X minutes (e.g. 30 min)
   - No history, no persistence

2. **Registered Mode (optional):**
   - Devise with simple sign-up (email + password, or better: Google OAuth for 1-click)
   - Benefits of registering: history of processed files, higher file size limit, saved preferences
   - **Never mandatory** — the "Sign up" button should be visible but must not block the main flow

**Implementation:**
- All processing routes (`/merge`, `/split`, etc.) work without `before_action :authenticate_user!`
- Use optional `current_user` (`current_user || GuestUser.new`) to differentiate limits/features
- Cleanup job (Sidekiq cron) that deletes guest files after a defined time

---

## Features (Priority Order)

### Tier 1 (MUST HAVE)
1. **Merge PDFs** – Drag-drop multiple files, reorder, download
2. **Split PDF** – Extract one or multiple page ranges simultaneously:
   - Range A: pages 1-5 → generates PDF_A
   - Range B: pages 10-15 → generates PDF_B
   - Individual download or ZIP with all of them
3. **Rotate Pages** – 90°/180°/270° per page
4. **Delete Pages** – Select and remove

### Tier 2 (SHOULD HAVE)
5. **Compress PDF** – Reduce size (configurable quality)
6. **JPG ↔ PDF** – Bidirectional conversion
7. **Watermark** – Text or image overlay on pages
8. **Unlock PDF** – Remove password (with the user's own permission, not malicious bypass)
9. **Protect PDF** – Add password/encryption
10. **OCR** – Extract text from scanned PDFs (Tesseract, background job)
11. **Office → PDF Conversion** – Word/Excel/PowerPoint → PDF (headless LibreOffice, background job)

### Tier 3 (NICE TO HAVE)
- Visual drag-drop page reordering
- File history (registered users only)
- Batch processing

---

## Quality Requirements

### Performance
- Heavy processes (OCR, Office conversion) go to **background jobs (Sidekiq)**, never block the request
- Real-time feedback via Turbo Streams ("Processing..." → "Done, download here")
- Configurable file size limit (e.g. 20MB guest, 50MB registered)

### Robustness
- File type validation (real content-type, not just extension)
- Error handling: corrupted file, LibreOffice timeout, memory issues
- Clear logs for debugging on Render (use Rails logger + possible Sentry integration if it scales)

### Privacy
- Clear message: "Your files are processed on our server and automatically deleted within 30 minutes"
- Automatic cleanup (Sidekiq cron job or scheduled ActiveJob)
- No logging of file contents, only metadata (size, type, timestamp)

### UX
- Mobile-first responsive
- Intuitive drag-drop
- Visual progress for long jobs (OCR, conversion)
- Zero-friction onboarding: land and use without forced welcome screens

---

## Project Structure (Rails Convention)

```
/app
  /controllers
    pdf_operations_controller.rb
    conversions_controller.rb
    registrations_controller.rb (Devise override if needed)
  /models
    processed_file.rb (file tracking, even guest via session_id)
    user.rb (Devise)
  /jobs
    ocr_job.rb
    office_conversion_job.rb
    file_cleanup_job.rb
  /services
    pdf_merger_service.rb
    pdf_splitter_service.rb
    watermark_service.rb
    encryption_service.rb
  /views
    /pdf_operations
    /shared (_upload_zone.html.erb, _progress.html.erb)
  /javascript/controllers (Stimulus controllers for drag-drop, progress)
/config
  Dockerfile (includes LibreOffice + Tesseract)
  render.yaml (blueprint for deploy: web + worker + postgres + redis)
```

---

## Deploy on Render

- **render.yaml** with blueprint: Web Service (Rails) + Background Worker (Sidekiq) + PostgreSQL + Redis
- Custom Dockerfile installing:
  ```dockerfile
  RUN apt-get update && apt-get install -y libreoffice tesseract-ocr qpdf
  ```
- Free tier for demo/testing → accept cold starts after 15 min of inactivity
- Environment variables: `RAILS_MASTER_KEY`, `DATABASE_URL`, `REDIS_URL` (Render auto-generates these with the blueprint)

---

## V1 Delivery Checklist

- [ ] Merge + Split (multi-range) + Rotate + Delete functional
- [ ] Compress + JPG↔PDF working
- [ ] Watermark + Unlock + Protect implemented
- [ ] OCR working via background job
- [ ] Office → PDF conversion working via background job
- [ ] Guest Mode functional (no login, zero friction)
- [ ] Registered Mode with Devise (optional, non-blocking)
- [ ] Automatic file cleanup (guest and timeout)
- [ ] Successful deploy on Render (Web + Worker + Postgres + Redis)
- [ ] Dockerfile with LibreOffice + Tesseract running on Render
- [ ] Manual testing: normal PDFs, protected PDFs, scanned PDFs, real Office files
- [ ] README with local setup + deploy instructions (for portfolio/interview)

---

## Note for Portfolio/Interview

This project should reflect good Rails practices:
- Service objects (no business logic in controllers)
- Background jobs for anything heavy
- Basic tests (RSpec or Minitest) for at least the critical services
- Professional README explaining architecture and technical decisions

---

**Go.**
