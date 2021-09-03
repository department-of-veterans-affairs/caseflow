# frozen_string_literal: true

# Model to represent the mode in which a user (e.g., an attorney) is working on a case.
# Specifically, the `overtime` field captures whether the appeal is being worked as overtime for the attorney.

class WorkMode < ApplicationRecord
  include HasAppealUpdatedSince

  belongs_to :appeal, polymorphic: true

  validates :appeal_id, presence: true
  validates :appeal_type, presence: true

  def self.create_or_update_by_appeal(appeal, attrs)
    work_mode = appeal.work_mode || WorkMode.new(appeal: appeal).tap { appeal.reload }
    return work_mode if work_mode.update(attrs)

    fail Caseflow::Error::WorkModeCouldNotUpdateError
  end
end
