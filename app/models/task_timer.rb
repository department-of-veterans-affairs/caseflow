class TaskTimer < ApplicationRecord
  include Asyncable

  REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 24

  belongs_to :task
end
