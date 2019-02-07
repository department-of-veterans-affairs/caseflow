class TaskAssociatedObject < ApplicationRecord
  belongs_to :hold_hearing_task
  belongs_to :hearing, polymorphic: true
end
