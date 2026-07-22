class SpaController < ActionController::Base
  def index
    index_html = Rails.public_path.join("index.html")
    if index_html.exist?
      send_file index_html, type: "text/html", disposition: "inline"
    else
      render plain: "SPA build not found. In development run: cd client && npm run dev", status: :ok
    end
  end
end
