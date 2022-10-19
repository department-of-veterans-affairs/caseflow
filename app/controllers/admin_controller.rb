# frozen_string_literal: true

class AdminController < ApplicationController
  skip_before_action :verify_authentication, only: [
    :show,
    :index
  ]

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "admin/index" }
    end
  end

  def index
    render "admin/index"
  end
end
