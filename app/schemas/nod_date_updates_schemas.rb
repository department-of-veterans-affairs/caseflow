# frozen_string_literal: true

class NodDateUpdatesSchemas
  class << self
    def update
      ControllerSchema.json do
        string :appeal_id
        string :change_reason, included_in?: %w[entry_error new_info]
        date :receipt_date
      end
    end
  end
end
