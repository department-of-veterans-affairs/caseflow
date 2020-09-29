# frozen_string_literal: true

##
# Validates the parent task
#
# Usage example: For the parent field, calls the built-in PresenceValidator and
# ParentTaskValidator with argument DistributionTask when the record is being created:
#   validates :parent, presence: true, parentTask: { task_type: DistributionTask }, on: :create

class ParentTaskValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:parent, "parent should be a #{options[:task_type].name}") unless correct_parent_type?(record)
  end

  private

  def correct_parent_type?(record)
    return true if options[:task_type].nil?

    record.parent&.type == options[:task_type].name
  end
end
