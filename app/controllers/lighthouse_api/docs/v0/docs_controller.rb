module LighthouseApi
  module Docs
    module V0
      class DocsController < LighthouseApi::ApiController
        def decision_reviews
          swagger = YAML.safe_load(File.read('app/controllers/lighthouse_api/docs/v0/decision_reviews.yaml'))
          render json: swagger
        end
      end
    end
  end
end
