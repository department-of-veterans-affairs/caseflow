class Reader::ApplicationController < ApplicationController
  before_action :verify_access, :verify_user_not_on_blacklist, :react_routed, :check_reader_out_of_service

  def set_application
    RequestStore.store[:application] = "reader"
  end

  def verify_access
    verify_authorized_roles("Reader")
  end

  def verify_user_not_on_blacklist
    redirect_to "/unauthorized" if feature_enabled?(:reader_blacklist)
  end

  private

  def check_reader_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("reader_out_of_service")
  end
end
