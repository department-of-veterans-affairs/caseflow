class UsersController < ApplicationController
  before_action :verify_queue_access, only: :index

  def index
    case params[:role]
    when "Judge"
      return render json: { judges: Judge.list_all }
    when "Attorney"
      return render json: { attorneys: Judge.new(judge).attorneys }
    end
    render json: {}
  end

  def judge
    @judge ||= User.find_by(css_id: params[:judge_css_id], station_id: User::BOARD_STATION_ID)
  end
end
