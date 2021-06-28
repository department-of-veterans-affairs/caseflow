# frozen_string_literal: true

class DocketSwitchesSchemas
  class << self
    def address_ruling
      ControllerSchema.json do
        string :task_id, doc: "Task ID of the DocketSwitchRulingTask"
        string :new_task_type, included_in?: %w[DocketSwitchGrantedTask DocketSwitchDeniedTask]
        string :instructions
        integer :assigned_to_user_id, doc: "User ID of an OCB Attorney"
      end
    end
  end
end
