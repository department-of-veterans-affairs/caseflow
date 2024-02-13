# frozen_string_literal: true

class ReassignPackageTask < CorrespondenceTask
  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REMOVE_PACKAGE_TASK_MODAL_URL
  end
end
