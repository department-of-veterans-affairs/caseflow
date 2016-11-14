class DevUsersController < ApplicationController
  def index
    @users = User.all
    render "index"
  end
end