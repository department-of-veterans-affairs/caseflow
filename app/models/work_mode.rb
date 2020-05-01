# frozen_string_literal: true

# Model to represent the mode in which a user (e.g., an attorney) is working on a case.
# Specifically, the `overtime` field captures whether the appeal is being worked as overtime for the attorney.

class WorkMode < ApplicationRecord
  belongs_to :appeal, polymorphic: true

  def self.create_or_update_by_appeal(appeal, attrs)
    work_mode = appeal.work_mode || WorkMode.new(appeal: appeal).tap { appeal.reload }
    work_mode.update(attrs)
    work_mode
  end
end
