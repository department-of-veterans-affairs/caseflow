# frozen_string_literal: true

class AdminController < ApplicationController
  skip_before_action :verify_authentication [
    :show
  ]

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "admin/index" }
    end
  end
end
