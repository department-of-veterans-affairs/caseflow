# frozen_string_literal: true

class Organizations::TaskSummaryController < OrganizationsController
  # rubocop:disable Metrics/MethodLength
  def index
    redirect_to "/unauthorized" unless organization.users.include?(current_user)

    result = ActiveRecord::Base.connection.exec_query(%{
      select count(*) as count
      , tasks.type as type
      , coalesce(la.closest_regional_office, a.closest_regional_office) as regional_office
      from tasks
      left join legacy_appeals la
        on tasks.appeal_id = la.id
        and tasks.appeal_type = 'LegacyAppeal'
      left join appeals a
        on tasks.appeal_id = a.id
        and tasks.appeal_type = 'Appeal'
      where assigned_to_id = #{organization.id}
        and assigned_to_type = 'Organization'
        and status in ('assigned', 'in_progress')
      -- Exclude TimedHoldTasks from being available for bulk assignment because they should not have child tasks
      -- and should only be created as children of NoShowHearingTasks, and those tasks will become available for
      -- bulk assignment after the timed hold has been completed.
        and tasks.type <> 'TimedHoldTask'
      group by 2, 3
      order by 2, 1 desc;
    })

    respond_to do |format|
      format.json do
        render json: {
          members: json_users(organization.users),
          task_counts: result.to_hash.to_json
        }
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def organization_url
    params[:organization_url]
  end

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end
end
