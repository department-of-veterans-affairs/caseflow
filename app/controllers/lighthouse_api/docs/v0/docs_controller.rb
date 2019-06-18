module LighthouseApi
  module Docs
    module V0
      class DocsController < ApplicationController
        def intakes
          swagger = YAML.safe_load(File.read('intakes.yaml'))
          render json: swagger
        end
      end
    end
  end
end