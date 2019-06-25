class Api::Docs::V0::DocsController < ActionController::Base
  def decision_reviews
    swagger = YAML.safe_load(File.read('app/controllers/api/docs/v0/decision_reviews.yaml'))
    render json: swagger
  end
end
