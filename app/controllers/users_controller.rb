class UsersController < ApplicationController
  before_action :verify_queue_access, only: :index

  def index
    case params[:role]
    when "Judge"
      return render json: { judges: Judge.list_all }
    when "Attorney"
      return render json: { attorneys: Judge.new(current_user).attorneys }
    end
    render json: {}
  end
end
