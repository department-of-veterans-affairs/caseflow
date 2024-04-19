# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include CorrespondenceControllerConcern
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts

  private

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
