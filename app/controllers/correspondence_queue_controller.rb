# frozen_string_literal: true

class CorrespondenceQueueController < CorrespondenceController
  def correspondence_cases
    if current_user.mail_supervisor?
      redirect_to "/queue/correspondence/team"
    elsif current_user.mail_superuser? || current_user.mail_team_user?
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
end
