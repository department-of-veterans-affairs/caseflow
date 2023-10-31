# frozen_string_literal: true

class CorrespondenceController < ApplicationController
  # before_action :verify_feature_toggle

  def correspondence_cases
    render 'correspondence_cases'
  end

  private

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue)
      redirect_to "/unauthorized"
    end
  end
end
