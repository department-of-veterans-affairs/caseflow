# frozen_string_literal: true

class NodDateEdit < CaseflowRecord
  belongs_to :appeal
  belongs_to :created_by, class_name: "User"

  validates :appeal, :created_by, :old_value, :new_value, :change_reason, presence: true

  enum change_reason: {
    entry_error: "entry_error",
    new_info: "new_info"
  }
end
