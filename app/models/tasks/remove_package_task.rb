# frozen_string_literal: true

class RemovePackageTask < CorrespondenceTask
  before_create :verify_no_other_open_package_action_task_on_correspondence

  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REMOVE_PACKAGE_TASK_MODAL_URL
  end
end
