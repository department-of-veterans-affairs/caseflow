# frozen_string_literal: true

# :reek:FeatureEnvy
class AutoAssignableUserFinder
  AssignableUser = Struct.new(:user_obj, :last_assigned_date, :num_assigned, :nod?, keyword_init: true)

  def assignable_users_exist?
    return false if FeatureToggle.enabled?(:auto_assign_banner_max_queue)

    assignable_users.count.positive?
  end

  def get_first_assignable_user(correspondence:)
    vbms_id = correspondence.veteran.file_number

    run_auto_assign_algorithm(correspondence, vbms_id)
  end

  private

  def run_auto_assign_algorithm(correspondence, vbms_id)
    assignable_users.each do |user|
      next if correspondence.nod && !user.nod?

      user_obj = user.user_obj

      if sensitivity_checker(user_obj).can_access?(vbms_id, user_to_check: user_obj)
        return user_obj
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
    InboundOpsTeam.singleton.users.includes(:tasks, :organizations, :organization_user_permissions)
      .where(
        organization_user_permissions: {
          organization_permission: OrganizationPermission.auto_assign(InboundOpsTeam.singleton),
          permitted: true
        }
      )
      .references(:tasks, :organizations, :organization_user_permissions)
  end

  def sensitivity_checker(user)
    @sensitivity_checker ||= ActiveSupport::HashWithIndifferentAccess.new

    return @sensitivity_checker[user.css_id] if @sensitivity_checker.key?(user.css_id)

    @sensitivity_checker[user.css_id] = BGSService.new(client: BGSService.init_client_for_user(user: user))

    @sensitivity_checker[user.css_id]
  end

  def permission_checker
    @permission_checker ||= OrganizationUserPermissionChecker.new
  end
end
