require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "loads with the Spanish headline by default" do
    visit root_path

    assert_text "Tus PDFs, resueltos"
  end

  test "the language switcher flips to English" do
    visit root_path
    click_on "EN"

    assert_text "Your PDFs, sorted"
  end
end
