# frozen_string_literal: true

class Api::Docs::V3::DocsController < ActionController::Base
  protect_from_forgery with: :null_session
  def decision_reviews
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/decision_reviews.yaml"))
    render json: swagger
  end
end
