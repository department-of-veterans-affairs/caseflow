# frozen_string_literal: true

class CorrespondenceController < ApplicationController
  before_action :verify_feature_toggle

  def intake
    render "correspondence/intake"
  end

  private

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue)
      redirect_to "/unauthorized"
    end
  end
end
