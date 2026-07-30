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
  end
end
