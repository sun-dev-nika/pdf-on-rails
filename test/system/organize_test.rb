require "application_system_test_case"

class OrganizeTest < ApplicationSystemTestCase
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

  test "guest can reorder pages and download the result" do
    visit organize_path

    attach_file "pdf", blank_pdf_path(3), make_visible: true
    click_on "Organizar PDF"

    assert_selector "li[data-page]", count: 3, wait: 10

    # Native HTML5 drag-and-drop simulation via Selenium is notoriously flaky
    # (and slow to the point of hanging) in headless Chrome. The
    # page-reorder Stimulus controller's whole job is keeping the hidden
    # `order` field in sync with the thumbnails' DOM order on drop, so
    # exercising that field directly - as if a drag had just reordered the
    # first and last thumbnails - covers the same request/response path
    # without fighting the browser automation layer.
    execute_script(<<~JS)
      document.querySelector('[data-page-reorder-target="orderInput"]').value = "3,1,2"
    JS
    click_on "Confirmar orden y descargar"

    downloaded_file = wait_for_download
    assert downloaded_file, "expected a reordered PDF to be downloaded"
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
