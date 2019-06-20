# frozen_string_literal: true

class HearingTaskAssociation < ApplicationRecord
  belongs_to :hearing_task
  belongs_to :hearing, polymorphic: true

  validates :hearing_task_id, uniqueness: {
    scope: [:hearing_type, :hearing_id],
    message: lambda do |object, _data|
      format(
        COPY::HEARING_TASK_ASSOCIATION_NOT_UNIQUE_MESSAGE,
        object.hearing_type,
        object.hearing_id,
        object.hearing_task_id
      )
    end
  }
end
