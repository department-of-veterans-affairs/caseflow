# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class Api::Docs::V3::DocsController < ActionController::Base
  def decision_reviews
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/decision_reviews.yaml"))
    render json: swagger
  end

  def ama_issues
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/ama_issues.yaml"))
    render json: swagger
  end

  def vacols_issues
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/vacols_issues.yaml"))
    render json: swagger
  end
end
# rubocop:enable Rails/ApplicationController
