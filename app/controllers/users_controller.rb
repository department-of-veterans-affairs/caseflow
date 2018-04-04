class UsersController < ApplicationController
  before_action :verify_queue_access, only: :index

  def index
    case params[:role]
    when "Judge"
      return render json: { judges: Judge.list_all }
    end
    render json: {}
  end
end
