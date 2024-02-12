# frozen_string_literal: true

class AutoAssignableUserFinder
  # TODO: APPEALS-38551: Switch to working directly with DB records.
  # Correspondence auto-assignment can be triggered via multiple methods,
  # so a local cache of this data can easily become invalid. Thus, we need
  # to work with the DB as our source of truth at every step
  AssignableUser = Struct.new(:id, :last_assigned_date, :num_assigned, :nod?, keyword_init: true)

  def assignable_users_exist?
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
      if sensitivity_checker.user_can_access?(vbms_id: vbms_id, user_to_check: user)
        # TODO: APPEALS-38551: Find not needed here
        return User.find(user.id)
      end
    end

    nil
  end

  def auto_assign_nod(vbms_id)
    assignable_users.each do |user|
      next if !user.nod?

      if sensitivity_checker.user_can_access?(vbms_id: vbms_id, user_to_check: user)
        # TODO: APPEALS-38551: Find not needed here
        return User.find(user.id)
      end
    end

    nil
  end

  # TODO: APPEALS-38551: Stub; complete in ticket
  # SQL query to get started with; note that you'll need queries for various user types
  # Helpful: http://www.scuttle.io/
=begin
SELECT users.id,
  COUNT(tasks.id) AS num_assigned
FROM users
  INNER JOIN tasks ON tasks.assigned_to_id  = users.id
WHERE
  tasks.assigned_to_type = 'User'
  AND
  tasks.appeal_type = 'Correspondence'
  AND
  tasks.type = 'ReviewPackageTask'
GROUP BY users.id
HAVING COUNT(tasks.id) < 60;
=end
  def assignable_users
    return @assignable_users if @assignable_users.present?

    # TODO: APPEALS-38551: Use in query
    # max_tasks = Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.max_assigned_tasks

    @assignable_users = []
    # TODO: APPEALS-38551: Filter such that only users with auto_assign == true are in this result set
    # Need to join to organization_user_permissions
    eligible = InboundOpsTeam.singleton.users.includes(:tasks)

    eligible.each do |user|
      # TODO: APPEALS-38551: Remove this struct and switch to working directly with DB records
      assignable = AssignableUser.new(
        id: user.id,
        last_assigned_date: Time.zone.now,
        num_assigned: user.tasks.count,
        nod?: true
      )

      @assignable_users.push(assignable)
    end

    @assignable_users
  end

  def sensitivity_checker
    @sensitivity_checker ||= ExternalApi::BGSService.new
  end
end
