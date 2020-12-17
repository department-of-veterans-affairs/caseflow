# frozen_string_literal: true

class NodDateEdit < CaseflowRecord
  belongs_to :appeal
  belongs_to :user

  validates :appeal, :user, :old_value, :new_value, :change_reason, presence: true

  enum change_reason: {
    entry_error: "entry_error",
    new_info: "new_info"
  }
end
