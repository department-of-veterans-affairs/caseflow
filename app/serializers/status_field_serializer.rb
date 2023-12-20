# frozen_string_literal: true

module StatusFieldSerializer
  extend ActiveSupport::Concern

  class_methods do
    protected

    def status(object)
      StatusSerializer.new(object).serializable_hash[:data][:attributes]
    end
  end
end
