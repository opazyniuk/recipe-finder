module Api
  module V1
    class BaseController < ActionController::API
      before_action { request.format = :json }

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
