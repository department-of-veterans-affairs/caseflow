class SavedSearchesController < ApplicationController
  include ValidationConcern

  before_action :verify_access


  def index
  end

  def show
  end

  def create
  end

  def destroy
  end

  private

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end
end
