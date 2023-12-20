# frozen_string_literal: true

# Veterans Health Administration related seeds
# require "/sanitized_json_seeds.rb"

module Seeds
  class BusinessLineOrg < Base
    def seed!
      create_business_lines
    end

    private
    def create_business_lines
        Seeds::SanitizedJsonSeeds.new.business_line_seeds
    end
  end
end
