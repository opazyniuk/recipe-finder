# frozen_string_literal: true

class Recipes::Finder
  Result = Data.define(:cook_now, :almost, :cook_now_total, :almost_total, :page, :per_page, :has_more) do
    def self.from_matches(matches, cook_now_total:, almost_total:, page:, per_page:, has_more:)
      cook_now, almost = matches.partition(&:cook_now?)
      new(cook_now:, almost:, cook_now_total:, almost_total:, page:, per_page:, has_more:)
    end
  end
end
