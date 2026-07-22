module Api
  module V1
    class RecipesController < BaseController
      def search
        @result = Recipes::Finder.call(
          pantry: pantry,
          difficulty: permitted_params[:difficulty],
          diet: permitted_params[:diet],
          min_rating: permitted_params[:min_rating],
          page: permitted_params.fetch(:page, 1)
        )
      end

      def show
        @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(permitted_params[:id])
        @pantry = pantry
      end

      private

      def permitted_params
        @permitted_params ||= params.permit(:id, :page, :include_staples, :difficulty, :diet, :min_rating,
                                            ingredient_ids: [])
      end

      def pantry
        Pantry.new(
          selected_ids: permitted_params[:ingredient_ids],
          include_staples: permitted_params.fetch(:include_staples, true)
        )
      end
    end
  end
end
