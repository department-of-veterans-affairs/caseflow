# frozen_string_literal: true

class Api::ExternalProxyController < ActionController::Base
  protect_from_forgery with: :null_session
end
