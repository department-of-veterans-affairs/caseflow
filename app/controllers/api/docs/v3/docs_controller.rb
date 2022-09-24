# frozen_string_literal: true

class Api::Docs::V3::DocsController < ApplicationController
  def decision_reviews
    swagger = YAML.safe_load(File.read("app/controllers/api/docs/v3/decision_reviews.yaml"))
    render json: swagger
  end
end
