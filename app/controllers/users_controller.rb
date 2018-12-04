class UsersController < ApplicationController
  def index
    case params[:role]
    when Constants::USER_ROLE_TYPES["judge"]
      return render json: { judges: Judge.list_all }
    when Constants::USER_ROLE_TYPES["attorney"]
      return render json: { attorneys: Judge.new(judge).attorneys } if params[:judge_css_id]
      return render json: { attorneys: Attorney.list_all }
    when Constants::USER_ROLE_TYPES["hearing_coordinator"]
      return render json: { coordinators: User.list_hearing_coordinators }
    when Constants::USER_ROLE_TYPES["hearing_judge"]
      # This method includes attorney id which is required for hearings
      return render json: { hearingJudges: Judge.list_all_with_name_and_id }
    end
    render json: {}
  end

  def judge
    @judge ||= User.find_by(css_id: params[:judge_css_id], station_id: User::BOARD_STATION_ID)
  end
end
