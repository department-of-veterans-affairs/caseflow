class CertificationsController < ApplicationController
  def new
    @appeal = Appeal.find(params[:vacols_id])
  end
end
