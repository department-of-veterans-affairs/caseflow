# frozen_string_literal: true

module ProdtestOnlyConcern
  extend ActiveSupport::Concern

  included do
    # before_action :prodtest_only
  end

  # Only accessible from prod-test environment
  def prodtest_only
    return true if Rails.deploy_env?(:prodtest)

    redirect_to "/404"
  end
end
