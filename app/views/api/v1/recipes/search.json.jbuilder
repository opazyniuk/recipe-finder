json.cook_now @result.cook_now, partial: "api/v1/recipes/match", as: :match
json.almost   @result.almost,   partial: "api/v1/recipes/match", as: :match
json.page     @result.page
json.per_page @result.per_page
json.has_more @result.has_more
json.cook_now_total @result.cook_now_total
json.almost_total   @result.almost_total
