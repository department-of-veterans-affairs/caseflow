# frozen_string_literal: true

class ClaimReviewSchemas
  class << self
    def edit_ep
      ControllerSchema.json do
        string :previous_code
        string :selected_code
      end
    end
  end
end
