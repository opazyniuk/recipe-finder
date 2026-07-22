module Api
  module V1
    class IngredientsController < BaseController
      def index
        return render(json: []) if prepared_query.blank?

        @ingredients = Ingredients::Search.autocomplete(prepared_query)
      end

      def popular
        @ingredients = Ingredients::Search.popular
      end

      private

      def prepared_query
        @prepared_query ||= permitted_params[:query].to_s.strip
      end

      def permitted_params
        @permitted_params ||= params.permit(:query)
      end
    end
  end
end
