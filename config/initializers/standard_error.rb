# frozen_string_literal: true

Rails.application.config.before_initialize do
  class StandardError
    def ignorable?
      false
    end
  end
end
