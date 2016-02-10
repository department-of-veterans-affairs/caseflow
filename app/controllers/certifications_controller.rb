class CertificationsController < ApplicationController
  layout "application"

  def new
    @appeal = Appeal.find(params[:vacols_id])
  end
end
