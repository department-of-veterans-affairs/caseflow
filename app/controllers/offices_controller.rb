class OfficesController < ApplicationController
  before_action :verify_authentication

  def list
    @offices = RegionalOffice.all
  end
end
