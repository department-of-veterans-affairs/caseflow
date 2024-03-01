# frozen_string_literal: true

module Seeds
  class CorrespondenceAutoAssignmentLevers < Base
    def seed!
      create_auto_assign_levers
    end

    def create_auto_assign_levers
      correspondence_auto_assignment_levers.each do |lever|
        CorrespondenceAutoAssignmentLever.find_or_create_by(name: lever[:name]) do |l|
          l.description = lever[:description]
          l.value = lever[:value]
          l.enabled = lever[:enabled]
        end
      end
    end

    private

    def correspondence_auto_assignment_levers
      capacity_description = <<~EOS
        Any Mail Team User or Mail Superuser with equal to or more than this amount will be excluded from Auto-assign
      EOS

      return [
        {
          name: "capacity",
          description: capacity_description,
          value: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.max_assigned_tasks,
          enabled: true
        }
      ]
    end
  end
end
