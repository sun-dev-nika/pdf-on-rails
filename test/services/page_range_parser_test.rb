require "test_helper"

class PageRangeParserTest < ActiveSupport::TestCase
  test "parses individual pages and ranges" do
    assert_equal [1, 2, 3, 5], PageRangeParser.parse("1-3, 5", total_pages: 10)
  end

  test "dedupes and sorts" do
    assert_equal [1, 2, 3], PageRangeParser.parse("3, 1-2, 2", total_pages: 10)
  end

  test "raises on blank input" do
    error = assert_raises(PageRangeParser::InvalidRange) { PageRangeParser.parse("", total_pages: 5) }
    assert_equal :blank, error.reason
  end

  test "raises on out-of-range pages" do
    error = assert_raises(PageRangeParser::InvalidRange) { PageRangeParser.parse("1,9", total_pages: 5) }
    assert_equal :out_of_range, error.reason
    assert_equal "9", error.params[:pages]
  end

  test "raises on backwards range" do
    error = assert_raises(PageRangeParser::InvalidRange) { PageRangeParser.parse("5-2", total_pages: 10) }
    assert_equal :backwards_range, error.reason
  end

  test "raises on invalid token" do
    error = assert_raises(PageRangeParser::InvalidRange) { PageRangeParser.parse("abc", total_pages: 10) }
    assert_equal :invalid_token, error.reason
  end
end
