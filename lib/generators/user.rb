# frozen_string_literal: true

class Generators::User
  extend Generators::Base

  class << self
    def default_attrs
      {
        station_id: "283",
        css_id: generate_external_id,
        full_name: "#{generate_first_name} #{generate_last_name}"
      }
    end

    def build(attrs = {})
      User.new(default_attrs.merge(attrs))
    end
  end
end
