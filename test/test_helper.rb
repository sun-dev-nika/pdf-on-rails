ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Builds a throwaway PDF with the given number of blank pages and
    # returns its path, for exercising the PDF service objects.
    def blank_pdf_path(pages)
      path = Rails.root.join("tmp", "test_pdf_#{SecureRandom.hex(6)}.pdf")
      doc = HexaPDF::Document.new
      pages.times { doc.pages.add }
      doc.write(path.to_s, optimize: true)
      path.to_s
    end

    # Rasterizes a throwaway one-page PDF into a real JPEG via Ghostscript,
    # for exercising the JPG <-> PDF conversion services.
    def sample_jpg_path
      pdf_path = blank_pdf_path(1)
      jpg_path = Rails.root.join("tmp", "test_jpg_#{SecureRandom.hex(6)}.jpg").to_s
      system("gs", "-dNOPAUSE", "-dBATCH", "-dQUIET", "-sDEVICE=jpeg", "-r72", "-o", jpg_path, pdf_path,
             exception: true)
      jpg_path
    end

    # Renders a one-page PDF containing real, OCR-recognizable text.
    def text_pdf_path(text)
      path = Rails.root.join("tmp", "test_pdf_#{SecureRandom.hex(6)}.pdf")
      doc = HexaPDF::Document.new
      canvas = doc.pages.add.canvas
      canvas.font("Helvetica", size: 30)
      canvas.text(text, at: [ 50, 700 ])
      doc.write(path.to_s, optimize: true)
      path.to_s
    end

    # A plain-text file LibreOffice can convert, for Office->PDF tests.
    def sample_text_document_path
      path = Rails.root.join("tmp", "test_doc_#{SecureRandom.hex(6)}.txt")
      File.write(path, "Hello from a test document.\n")
      path.to_s
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
