# frozen_string_literal: true

class CorrespondenceRootTask < CorrespondenceTask
  # a correspondence root task is considered closed if it has a closed at
  # date OR all children tasks are completed.
  def completed_by_date
    return closed_at unless closed_at.nil?

    if children&.all?(&:completed?)
      children.maximum(:closed_at)
    end
  end
end
