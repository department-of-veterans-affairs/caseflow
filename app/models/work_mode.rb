# frozen_string_literal: true

class WorkMode < ApplicationRecord
  belongs_to :appeal, polymorphic: true

  def self.create_or_update_by_appeal(appeal, attrs)
    work_mode = appeal.work_mode || WorkMode.new(appeal: appeal)
    work_mode.update(attrs)
    work_mode
  end
end
