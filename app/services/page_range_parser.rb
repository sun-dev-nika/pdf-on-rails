class PageRangeParser
  class InvalidRange < StandardError
    attr_reader :reason, :params

    def initialize(reason, **params)
      @reason = reason
      @params = params
      super(reason.to_s)
    end
  end

  def self.parse(input, total_pages:)
    new(input, total_pages: total_pages).parse
  end

  def initialize(input, total_pages:)
    @input = input.to_s
    @total_pages = total_pages
  end

  def parse
    pages = @input.split(",").flat_map { |part| parse_part(part.strip) }.uniq.sort
    raise InvalidRange.new(:blank) if pages.empty?

    out_of_range = pages.select { |page| page < 1 || page > @total_pages }
    if out_of_range.any?
      raise InvalidRange.new(:out_of_range, pages: out_of_range.join(", "), total: @total_pages)
    end

    pages
  end

  private

  def parse_part(part)
    return [] if part.empty?

    case part
    when /\A\d+\z/
      [ part.to_i ]
    when /\A(\d+)-(\d+)\z/
      start_page = Regexp.last_match(1).to_i
      end_page = Regexp.last_match(2).to_i
      raise InvalidRange.new(:backwards_range, range: part) if start_page > end_page

      (start_page..end_page).to_a
    else
      raise InvalidRange.new(:invalid_token, token: part)
    end
  end
end
