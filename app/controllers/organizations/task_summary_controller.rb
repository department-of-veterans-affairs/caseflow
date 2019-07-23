# frozen_string_literal: true

class Organizations::TaskSummaryController < OrganizationsController
  # rubocop:disable Metrics/MethodLength
  def index
    redirect_to "/unauthorized" unless organization.users.include?(current_user)

    result = ActiveRecord::Base.connection.exec_query(%{
      select count(*) as count
      , tasks.type as type
      , closest_regional_office as regional_office
      from tasks
      left join (
        select closest_regional_office
        , id
        , 'LegacyAppeal' as type
        from legacy_appeals
        union
        select closest_regional_office
        , id
        , 'Appeal' as type
        from appeals
      ) all_appeals
        on tasks.appeal_id = all_appeals.id
        and tasks.appeal_type = all_appeals.type
      where assigned_to_id = #{organization.id}
        and assigned_to_type = 'Organization'
        and status in ('assigned', 'in_progress')
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
