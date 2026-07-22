# frozen_string_literal: true

class Recipes::Finder
  PER_PAGE = 24
  MAX_MISSING = 2

  def self.call(...) = new(...).call

  def initialize(pantry:, difficulty: nil, diet: nil, min_rating: nil, page: 1)
    @pantry = pantry
    @difficulty = difficulty
    @diet = diet
    @min_rating = Float(min_rating, exception: false)
    @page = [ page.to_i, 1 ].max
  end

  def call
    return empty_result if @pantry.empty?

    query_results = ActiveRecord::Base.connection.exec_query(query_sql).to_a

    build_result(query_results)
  end

  def to_sql = query_sql

  private

  def build_result(query_results)
    matches = query_results.first(PER_PAGE).map { |row| Match.from_row(row) }
    totals = query_results.first || {}

    Result.from_matches(
      matches,
      cook_now_total: totals.fetch("cook_now_total", 0).to_i,
      almost_total: totals.fetch("almost_total", 0).to_i,
      page: @page, per_page: PER_PAGE, has_more: query_results.size > PER_PAGE
    )
  end

  def empty_result
    Result.from_matches([], cook_now_total: 0, almost_total: 0, page: @page, per_page: PER_PAGE, has_more: false)
  end

  def query_sql
    ActiveRecord::Base.sanitize_sql_array([ base_query, binds ])
  end

  RANKING = "missing_count ASC, coverage DESC, ratings DESC NULLS LAST, total_count ASC, id ASC"
  private_constant :RANKING

  def base_query
    <<~SQL
      WITH pantry_coverage AS (
        SELECT recipe_id,
               COUNT(*) AS have_count,
               COUNT(*) FILTER (WHERE ingredient_id IN (:selected)) AS selected_count
        FROM recipe_ingredients
        WHERE ingredient_id IN (:available)
        GROUP BY recipe_id
      ),
      ranked AS (
        SELECT r.id, r.title, r.image_url, r.total_time, r.prep_time, r.cook_time,
               r.ratings, r.category, r.cuisine,
               #{Difficulty.label_sql} AS difficulty,
               r.ingredients_count AS total_count,
               pc.have_count,
               r.ingredients_count - pc.have_count AS missing_count,
               pc.have_count::float / NULLIF(r.ingredients_count, 0) AS coverage,
               COUNT(*) FILTER (WHERE r.ingredients_count - pc.have_count = 0) OVER () AS cook_now_total,
               COUNT(*) FILTER (WHERE r.ingredients_count - pc.have_count > 0) OVER () AS almost_total
        FROM pantry_coverage pc
        JOIN recipes r ON r.id = pc.recipe_id
        WHERE pc.selected_count > 0
          AND r.ingredients_count - pc.have_count <= :max_missing
          AND #{extra_where_queries}
        ORDER BY #{RANKING}
        LIMIT :limit OFFSET :offset
      )
      SELECT ranked.*,
             (SELECT string_agg(i.name, '|' ORDER BY ri.position)
              FROM recipe_ingredients ri
              JOIN ingredients i ON i.id = ri.ingredient_id
              WHERE ri.recipe_id = ranked.id AND ri.ingredient_id NOT IN (:available)) AS missing_names
      FROM ranked
      ORDER BY #{RANKING}
    SQL
  end

  def extra_where_queries
    filters = [
      Difficulty.filter_sql(@difficulty),
      Diet.filter_sql(@diet),
      ("r.ratings >= :min_rating" if @min_rating)
    ].compact

    filters.empty? ? "TRUE" : filters.map { |clause| "(#{clause})" }.join(" AND ")
  end

  def binds
    {
      selected: @pantry.selected_ids,
      available: @pantry.available_ids,
      max_missing: MAX_MISSING,
      min_rating: @min_rating,
      limit: PER_PAGE + 1,
      offset: (@page - 1) * PER_PAGE
    }
  end
end
