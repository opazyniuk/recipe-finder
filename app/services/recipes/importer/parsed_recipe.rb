# frozen_string_literal: true

require "uri"

class Recipes::Importer
  ParsedRecipe = Data.define(:attributes, :lines) do
    def self.from(raw)
      new(attributes: attributes_for(raw), lines: lines_for(raw["ingredients"]))
    end

    def self.attributes_for(raw)
      {
        title: raw["title"].presence || "Untitled",
        image_url: resolve_image(raw["image"]),
        category: raw["category"].presence,
        cuisine: Recipes::Cuisine.for(raw["category"]),
        author: raw["author"].presence,
        prep_time: raw["prep_time"],
        cook_time: raw["cook_time"],
        total_time: total_minutes(raw["prep_time"], raw["cook_time"]),
        ratings: raw["ratings"]
      }
    end

    def self.lines_for(raw_ingredients)
      Array(raw_ingredients).each_with_index.filter_map do |raw, idx|
        next unless (parsed = Ingredients::Parser.call(raw))

        { name: parsed.name, quantity: parsed.quantity, unit: parsed.unit, raw: raw, position: idx }
      end
    end

    def self.total_minutes(prep, cook)
      minutes = [ prep, cook ].compact.sum(&:to_i)
      minutes.positive? ? minutes : nil
    end

    def self.resolve_image(url)
      return nil if url.blank?

      uri = URI.parse(url)
      if uri.host&.include?("meredithcorp.io") && uri.query
        inner = URI.decode_www_form(uri.query).to_h["url"]
        return inner if inner.present?
      end
      url
    rescue URI::InvalidURIError, ArgumentError
      url
    end

    private_class_method :attributes_for, :lines_for, :total_minutes, :resolve_image
  end
end
