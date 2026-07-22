# frozen_string_literal: true

require "open-uri"
require "zlib"
require "stringio"

class Recipes::Importer
  class Dataset
    DEFAULT_SOURCE = ENV.fetch("RECIPES_DATASET_URL") { Rails.root.join("db/seeds/data/recipes-en.json.gz").to_s }

    def initialize(source: DEFAULT_SOURCE, io: nil)
      @source = source
      @io = io
    end

    def records = JSON.parse(read)

    private

    def read
      return @io.read if @io

      Zlib::GzipReader.new(StringIO.new(source_bytes)).read
    end

    def source_bytes
      return URI.parse(@source).open.read if @source.to_s.match?(%r{\Ahttps?://})

      File.binread(@source)
    end
  end
end
