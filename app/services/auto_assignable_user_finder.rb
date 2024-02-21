# frozen_string_literal: true

# :reek:FeatureEnvy
class AutoAssignableUserFinder
  AssignableUser = Struct.new(:user_obj, :last_assigned_date, :num_assigned, :nod?, keyword_init: true)

  def assignable_users_exist?
    return false if FeatureToggle.enabled?(:auto_assign_banner_max_queue) && !Rails.env.production?

    assignable_users.count.positive?
  end

  def get_first_assignable_user(correspondence:)
    vbms_id = correspondence.veteran.file_number

    run_auto_assign_algorithm(correspondence, vbms_id)
  end

  private

  def run_auto_assign_algorithm(correspondence, vbms_id)
    return auto_assign_nod(vbms_id) if correspondence.nod?

    assignable_users.each do |user|
      if sensitivity_checker.user_can_access?(vbms_id: vbms_id, user_to_check: user.user_obj)
        return user.user_obj
      end
    end

    nil
  end

  def auto_assign_nod(vbms_id)
    assignable_users.each do |user|
      next if !user.nod?

      if sensitivity_checker.user_can_access?(vbms_id: vbms_id, user_to_check: user.user_obj)
        return user.user_obj
      end
    end

    nil
  end

  def assignable_users
    users = []

    find_users.each do |user|
      num_assigned = num_assigned_user_tasks(user)

      next if num_assigned >= CorrespondenceAutoAssignmentLever.max_capacity

      nod_eligible = permission_checker.can?(
        permission_name: Constants.ORGANIZATION_PERMISSIONS.receive_nod_mail,
        organization: InboundOpsTeam.singleton,
        user: user
      )

      assignable = AssignableUser.new(
        user_obj: user,
        last_assigned_date: user_review_package_tasks(user).maximum(:assigned_at),
        num_assigned: num_assigned,
        nod?: nod_eligible
      )

      users.push(assignable)
    end

    sorted_assignable_users(users)
  end

  # :reek:UncommunicativeVariableName
  def sorted_assignable_users(users)
    users.sort do |a, b|
      if a.num_assigned == b.num_assigned
        a.last_assigned_date <=> b.last_assigned_date
      else
        a.num_assigned <=> b.num_assigned
      end
    end
  end

  def num_assigned_user_tasks(user)
    count = user_review_package_tasks(user).count

    super_users = InboundOpsTeam.super_users
    if super_users.include?(user)
      count += ((MergePackageTask.count + ReassignPackageTask.count + SplitPackageTask.count) / super_users.count).round
    end

    count
  end

  def user_review_package_tasks(user)
    user.tasks.where(
      type: ReviewPackageTask.name,
      status: [
        Constants.TASK_STATUSES.assigned,
        Constants.TASK_STATUSES.in_progress,
        Constants.TASK_STATUSES.on_hold
      ]
    )
  end

  def find_users
    # Do NOT use manual caching here!!!
    # Other processes may update data, so always use the DB as the source of truth and let Rails handle any caching
    InboundOpsTeam.singleton.users.includes(:tasks, :organization_user_permissions)
      .where(
        organization_user_permissions: {
          organization_permission: OrganizationPermission.auto_assign(InboundOpsTeam.singleton),
          permitted: true
        }
      )
      .references(:tasks, :organization_user_permissions)
  end

  def sensitivity_checker
    return @sensitivity_checker if @sensitivity_checker.present?

    @sensitivity_checker = BGSService.new

    # TODO: Create seed data for this, add vbms_id here
    # if !Rails.env.production
    #   BGSService.mark_veteran_not_accessible()
    # end

    @sensitivity_checker
  end

  def permission_checker
    @permission_checker ||= OrganizationUserPermissionChecker.new
  end
end
