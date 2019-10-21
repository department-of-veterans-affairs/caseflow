# frozen_string_literal: true

class UserManagementController < ApplicationController
  before_action :deny_non_bva_admins

  def index
    render template: "queue/index"
  end
end
