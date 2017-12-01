class OfficesController < ApplicationController
  before_action :verify_authentication

  def index
    @offices = RegionalOffice.all
  end
end
