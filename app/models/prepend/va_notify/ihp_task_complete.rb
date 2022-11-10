# frozen_string_literal: true

# Module to notify appellant if IHP Task is Complete
module IhpTaskComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "VSO IHP complete"
  # rubocop:enable all

  rescue_from AppealTypeNotImplementedError do |exception|
    Rails.logger.error(exception)
    Rails.logger.error("Invalid Appeal Type for IhpTaskComplete")
  end

  # original method in app/models/task.rb
  def update_from_params(params, user)
    super_return_value = super
    if %w[InformalHearingPresentationTask IhpColocatedTask].include?(type) &&
       params[:status] == Constants.TASK_STATUSES.completed
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_complete")
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
