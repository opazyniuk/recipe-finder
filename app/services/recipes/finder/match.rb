# frozen_string_literal: true

class Recipes::Finder
  Match = Data.define(
    :id, :title, :image_url, :total_time, :prep_time, :cook_time, :ratings,
    :category, :cuisine, :difficulty, :have_count, :total_count, :missing_count, :missing_names
  ) do
    def self.from_row(row)
      new(
        id: row["id"], title: row["title"], image_url: row["image_url"],
        total_time: row["total_time"], prep_time: row["prep_time"], cook_time: row["cook_time"],
        ratings: row["ratings"], category: row["category"], cuisine: row["cuisine"], difficulty: row["difficulty"],
        have_count: row["have_count"], total_count: row["total_count"],
        missing_count: row["missing_count"], missing_names: row["missing_names"].to_s.split("|")
      )
    end

    def cook_now? = missing_count.zero?
  end
end
