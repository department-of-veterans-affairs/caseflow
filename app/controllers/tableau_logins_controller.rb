# frozen_string_literal: true

class TableauLoginsController < ApplicationController
  def login
    token = ExternalApi::TableauService.authenticate(current_user.username)
    redirect_to("/unauthorized") && return if token == ExternalApi::TableauService::ERROR_CODE.to_s

    redirect_to "https://bva-tableau.va.gov/trusted/#{token}/#{params[:path]}"
  rescue StandardError
    render "errors/500", layout: "application", status: :service_unavailable
  end
end
