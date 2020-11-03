# frozen_string_literal: true

class Api::V3::BaseController < Api::ApplicationController
  class << self
    def status_from_errors(errors)
      errors.map { |error| error[:status] || error["status"] }.max
    rescue StandardError
      500
    end
  end

  protect_from_forgery with: :null_session

  def render_errors(errors)
    errors = Array.wrap(errors)
    status = self.class.status_from_errors errors
    render status: status, json: { errors: errors }
  end
end
