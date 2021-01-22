# frozen_string_literal: true

class NodDateUpdatesSchemas
  class << self
    def update
      ControllerSchema.json do
        string :appeal_id
        string :user_id       
        string :change_reason, included_in?: %w[entry_error new_info]
        date :old_date
        date :new_date
        string :receipt_date
      end
    end
  end
end
