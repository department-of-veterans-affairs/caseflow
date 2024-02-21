# frozen_string_literal: true

class RemovePackageTask < CorrespondenceTask

  # :reek:UtilityFunction
  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REMOVE_PACKAGE_TASK_MODAL_URL
  end
end
