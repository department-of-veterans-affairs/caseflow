# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include CorrespondenceControllerConcern
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  private

  def update_veteran_on_correspondence
    veteran = Veteran.find_by(file_number: veteran_params["file_number"])
    veteran && correspondence.update(
      correspondence_params.merge(
        veteran_id: veteran.id,
        updated_by_id: RequestStore.store[:current_user].id
      )
    )
  end

  def update_open_review_package_tasks
    correspondence.tasks.open.where(type: ReviewPackageTask.name).each do |task|
      task.update(status: Constants.TASK_STATUSES.in_progress)
    end
  end

  def verify_correspondence_access
    return true if InboundOpsTeam.singleton.user_has_access?(current_user) ||
                   MailTeam.singleton.user_has_access?(current_user) ||
                   BvaIntake.singleton.user_is_admin?(current_user) ||
                   MailTeam.singleton.user_is_admin?(current_user)

    redirect_to "/unauthorized"
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue) && verify_correspondence_access
      redirect_to "/under_construction"
    elsif !FeatureToggle.enabled?(:correspondence_queue) || !verify_correspondence_access
      redirect_to "/unauthorized"
    end
  end
end
