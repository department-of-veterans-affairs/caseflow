# frozen_string_literal: true

class AdminController < ApplicationController
  skip_before_action :verify_authentication
end
