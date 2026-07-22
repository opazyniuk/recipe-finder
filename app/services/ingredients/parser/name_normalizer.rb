# frozen_string_literal: true

class Ingredients::Parser::NameNormalizer
  SIZES = %w[small medium large extra jumbo mini].to_set.freeze

  PREP = %w[
    chopped minced sliced diced softened soften melted shredded grated crushed
    cooked uncooked fresh freshly frozen ground packed sifted beaten drained
    undrained rinsed halved quartered cubed trimmed boneless skinless peeled
    seeded cored pitted stemmed deveined julienned thinly thickly finely coarsely
    roughly lightly lengthwise crosswise separated divided optional crumbled
    mashed toasted warmed warm cold room temperature very cut prepared
    inch thick thin each
  ].to_set.freeze

  CONNECTIVES = %w[of a an the to].to_set.freeze

  STOPWORDS = (Ingredients::Parser::UNIT_SURFACES + SIZES + PREP + CONNECTIVES).freeze

  TRAILING = /\s+(?:to taste|as needed|for (?:garnish|serving|dusting|decoration)|or more.*|plus more.*|divided|into\b.*)\z/i

  def self.call(raw) = new(raw).call

  def initialize(raw)
    @raw = raw.to_s
  end

  def call
    cleaned = clean_raw
    tokens = meaningful_tokens(cleaned)
    name = merge_prepared_tokens(tokens)
    seasoned = collapse_seasoning(name)
    collapse_variety(seasoned)
  end

  private

  attr_reader :raw

  def clean_raw
    I18n.transliterate(raw)
        .gsub(/\([^)]*\)/, " ")
        .tr(",", " ")
        .sub(/\s-\s.*\z/, " ")
        .sub(TRAILING, " ")
        .gsub(/[^a-zA-Z\s]/, " ")
        .downcase
        .sub(/\b(?:or|with|in)\b.*/m, " ")
  end

  def meaningful_tokens(text)
    tokens = text.split
                 .reject { |token| token.length < 2 || STOPWORDS.include?(token) }
                 .map { |token| singularize_token(token) }
    tokens.shift while tokens.first&.match?(/\A(?:and|or)\z/)
    tokens.pop while tokens.last&.match?(/\A(?:and|or)\z/)

    tokens
  end

  def merge_prepared_tokens(tokens)
    tokens.join(" ").squeeze(" ").strip
  end

  def collapse_seasoning(name)
    Ingredients::Parser::SeasoningCollapser.new(name).call
  end

  def collapse_variety(name)
    Ingredients::Parser::VarietyCollapser.new(name).call
  end

  def singularize_token(word)
    return word if word.length <= 3
    return word if word.end_with?("ss", "us", "is")

    case word
    when /\A(.+)ies\z/                then "#{$1}y"
    when /\A(.+(?:ch|sh|x|z|o))es\z/  then $1
    when /\A(.+)s\z/                  then $1
    else word
    end
  end
end
