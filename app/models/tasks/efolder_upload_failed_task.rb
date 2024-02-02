# frozen_string_literal: true

class EfolderUploadFailedTask < ReviewPackageTask
  def task_url
    if parent.is_a?(ReviewPackageTask)
      Constants.CORRESPONDENCE_TASK_URL.REVIEW_PACKAGE_TASK_URL.sub("uuid", correspondence.uuid)
    elsif parent.is_a?(CorrespondenceIntakeTask)
      Constants.CORRESPONDENCE_TASK_URL.INTAKE_TASK_URL.sub("uuid", correspondence.uuid)
    end
  end
end
