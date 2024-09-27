# frozen_string_literal: true

# For correspondence auto assignment, determines whether any assignable users exist as well as returns the first
# assignable user for a given correspondence

# :reek:FeatureEnvy
class AutoAssignableUserFinder
  AssignableUser = Struct.new(:user_obj, :last_assigned_date, :num_assigned, :nod?, keyword_init: true)

  attr_reader :unassignable_reasons

  def initialize(current_user)
    self.current_user = current_user
    self.unassignable_reasons = []
  end

  def assignable_users_exist?
    return false if FeatureToggle.enabled?(:auto_assign_banner_max_queue)

    assignable_users.count.positive?
  end

  def get_first_assignable_user(correspondence:)
    run_auto_assign_algorithm(correspondence, assignable_users)
  end

  def can_user_work_this_correspondence?(user:, correspondence:)
    return false if user_is_at_max_capacity?(user)

    assignable = user_to_assignable_user(user)

    run_auto_assign_algorithm(correspondence, [assignable]).present?
  end

  private

  attr_accessor :current_user
  attr_writer :unassignable_reasons

  def run_auto_assign_algorithm(correspondence, users)
    nod_error = Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.NOD_ERROR
    sensitivity_error = Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.SENSITIVITY_ERROR
    users.each do |user|
      if correspondence.nod && !user.nod?
        unassignable_reasons << nod_error
        next
      end

      user_obj = user.user_obj

      if sensitivity_levels_compatible?(user: user_obj, veteran: correspondence.veteran)
        return user_obj
      else
        unassignable_reasons << sensitivity_error
      end
    end

    nil
  end

  def user_is_at_max_capacity?(user)
    capacity_error = Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.CAPACITY_ERROR
    if num_assigned_user_tasks(user) >= CorrespondenceAutoAssignmentLever.max_capacity
      unassignable_reasons << capacity_error
      true
    else
      false
    end
  end

  def assignable_users
    users = []

    find_users.each do |user|
      next if user_is_at_max_capacity?(user)

      assignable = user_to_assignable_user(user)

      users.push(assignable)
    end

    sorted_assignable_users(users)
  end

  def user_to_assignable_user(user)
    nod_eligible = permission_checker.can?(
      permission_name: Constants.ORGANIZATION_PERMISSIONS.receive_nod_mail,
      organization: InboundOpsTeam.singleton,
      user: user
    )

    AssignableUser.new(
      user_obj: user,
      last_assigned_date: user_review_package_tasks(user).maximum(:assigned_at),
      num_assigned: num_assigned_user_tasks(user),
      nod?: nod_eligible
    )
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

  def sensitivity_levels_compatible?(user:, veteran:)
    begin
      sensitivity_checker.sensitivity_level_for_user(user) >=
        sensitivity_checker.sensitivity_level_for_veteran(veteran)
    rescue StandardError => error
      error_uuid = SecureRandom.uuid
      Raven.capture_exception(error, extra: { error_uuid: error_uuid })

      false
    end
  end

  def sensitivity_checker
    return @sensitivity_checker if @sensitivity_checker.present?

    # Set for use by BGSService
    RequestStore.store[:current_user] ||= current_user

    @sensitivity_checker = BGSService.new
  end

  def permission_checker
    @permission_checker ||= OrganizationUserPermissionChecker.new
  end
end
