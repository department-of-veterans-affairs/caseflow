# frozen_string_literal: true

class SplitPackageTask < CorrespondenceTask
  before_create :verify_no_other_open_package_action_task_on_correspondence

  def task_url
    "/under_construction"
  end
end
