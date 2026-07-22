# frozen_string_literal: true

class Ingredients::Parser::QuantityExtractor
  UNICODE_FRACTIONS = {
    "¼" => 0.25, "½" => 0.5, "¾" => 0.75,
    "⅓" => 1.0 / 3, "⅔" => 2.0 / 3,
    "⅕" => 0.2, "⅖" => 0.4, "⅗" => 0.6, "⅘" => 0.8,
    "⅙" => 1.0 / 6, "⅚" => 5.0 / 6,
    "⅛" => 0.125, "⅜" => 0.375, "⅝" => 0.625, "⅞" => 0.875,
    "⅐" => 1.0 / 7, "⅑" => 1.0 / 9, "⅒" => 0.1
  }.freeze
  FRACTION_CHARS = UNICODE_FRACTIONS.keys.join.freeze

  def self.call(raw) = new(raw).call

  def initialize(raw)
    @raw = raw.to_s
  end

  def call
    scanner = @raw.lstrip
    total = 0.0
    found = false
    loop do
      break if scanner.start_with?("(")

      if (m = scanner.match(%r{\A(\d+)\s*/\s*(\d+)}))
        total += m[1].to_f / m[2].to_f
      elsif (m = scanner.match(/\A(\d+\.\d+)/))
        total += m[1].to_f
      elsif (m = scanner.match(/\A(\d+)/))
        total += m[1].to_i
      elsif (m = scanner.match(/\A([#{FRACTION_CHARS}])/))
        total += UNICODE_FRACTIONS[m[1]]
      else
        break
      end
      found = true
      scanner = m.post_match.lstrip
    end
    found ? total.round(4) : nil
  end
end
