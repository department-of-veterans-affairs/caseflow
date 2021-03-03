# frozen_string_literal: true

class NodDateUpdate < CaseflowRecord
  belongs_to :appeal
  belongs_to :user

  validates :appeal, :user, :old_date, :new_date, :change_reason, presence: true

  delegate :request_issues, to: :appeal

  enum change_reason: {
    entry_error: "entry_error",
    new_info: "new_info"
  }
end
