# frozen_string_literal: true

class Reader::ApplicationController < ApplicationController
  before_action :verify_access, :react_routed, :check_reader_out_of_service
  newrelic_ignore

  def set_application
    RequestStore.store[:application] = "reader"
  end

  def verify_access
    verify_authorized_roles("Reader")
  end

  private

  def check_reader_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("reader_out_of_service")
  end
end
