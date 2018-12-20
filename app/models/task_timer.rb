class TaskTimer < ApplicationRecord
  include Asyncable

  def submit_for_processing!(delay)
    super(delay: delay)
  end
end
