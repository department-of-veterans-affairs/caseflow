# frozen_string_literal: true

class AppealsSchemas
  class << self
    def update_nod_date
      ControllerSchema.json do |schema|
        schema.string :appeal_id
        schema.date :receipt_date
      end
    end
  end
end
