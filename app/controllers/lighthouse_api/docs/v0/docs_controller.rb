module LighthouseApi
  module Docs
    module V0
      class DocsController < LighthouseApi::ApiController
        def intakes
          swagger = YAML.safe_load(File.read('app/controllers/lighthouse_api/docs/v0/intakes.yaml'))
          render json: swagger
        end
      end
    end
  end
end
