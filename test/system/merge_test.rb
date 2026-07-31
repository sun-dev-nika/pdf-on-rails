require "application_system_test_case"

class MergeTest < ApplicationSystemTestCase
  DOWNLOADS_PATH = Rails.root.join("tmp/system_test_downloads")

  setup do
    FileUtils.mkdir_p(DOWNLOADS_PATH)
    page.driver.browser.execute_cdp(
      "Page.setDownloadBehavior", behavior: "allow", downloadPath: DOWNLOADS_PATH.to_s
    )
  end

  teardown do
    FileUtils.rm_rf(DOWNLOADS_PATH)
  end

  test "guest can merge two PDFs without an account" do
    visit merge_path

    attach_file "pdfs[]", [ blank_pdf_path(2), blank_pdf_path(3) ], make_visible: true
    click_on "Unir y descargar"

    downloaded_file = wait_for_download
    assert downloaded_file, "expected a merged PDF to be downloaded"
  end

  private

  def wait_for_download
    Timeout.timeout(10) do
      loop do
        files = Dir.glob(DOWNLOADS_PATH.join("*")).reject { |f| f.end_with?(".crdownload") }
        break files.first if files.any?

        sleep 0.1
      end
    end
  rescue Timeout::Error
    nil
  end
end
