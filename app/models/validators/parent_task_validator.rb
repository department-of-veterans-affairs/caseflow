# frozen_string_literal: true

##
# Validates the parent task
#
# Usage example: For the parent field, calls the built-in PresenceValidator and
# ParentTaskValidator with argument DistributionTask when the record is being created:
#   validates :parent, presence: true, parentTask: { task_type: DistributionTask }, on: :create

class ParentTaskValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:parent, error_message) unless correct_parent_type?(record)
  end

  private

  def correct_parent_type?(record)
    if multiple_correct_parent_types?
      return options[:task_types].any? { |task_type| record.parent.is_a? task_type }
    end

    return true if options[:task_type].nil?

    record.parent.is_a? options[:task_type]
  end

  def multiple_correct_parent_types?
    options[:task_types].present?
  end

  def error_message
    if multiple_correct_parent_types?
      return "should be one of #{options[:task_types].map(&:name).join(', ')}"
    end

    "should be a #{options[:task_type].name}"
  end
end
