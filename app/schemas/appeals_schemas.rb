# frozen_string_literal: true

class AppealsSchemas
  class << self
    def update_nod_date
      ControllerSchema.json do
        string :appeal_id
        date :receipt_date
      end
    end
  end
end
