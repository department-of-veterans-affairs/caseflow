# frozen_string_literal: true

module Api::V3::Concerns::Validation
  extend ActiveSupport::Concern
  include Api::V3::Concerns::Helpers

  DEFAULT_ERROR = Api::V3::MalformedRequestError
end
