# frozen_string_literal: true

class CorrespondenceQueueController < CorrespondenceController
  def correspondence_cases
    if current_user.mail_supervisor?
      redirect_to "/queue/correspondence/team"
    elsif current_user.mail_superuser? || current_user.mail_team_user?
      @action_type = params[:userAction].strip if params[:userAction].present?
      set_banner_params if %w[continue_later cancel_intake].include?(@action_type)
      respond_to do |format|
        format.html { "your_correspondence" }
        format.json do
          render json: { correspondence_config: CorrespondenceConfig.new(assignee: current_user) }
        end
      end
    else
      redirect_to "/unauthorized"
    end
  end

  def set_banner_params
    @veteran_name = URI.decode(params[:veteranName].strip) if params[:veteranName].present?
    set_handle_return_to_queue_params
  end
end
