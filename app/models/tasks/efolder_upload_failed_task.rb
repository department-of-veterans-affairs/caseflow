# frozen_string_literal: true

class EfolderUploadFailedTask < CorrespondenceTask
  def task_url
    if parent.type == ReviewPackageTask.name
      Constants.CORRESPONDENCE_TASK_URL.REVIEW_PACKAGE_TASK_URL.sub("uuid", correspondence.uuid)
    elsif parent.type == CorrespondenceIntakeTask.name
      Constants.CORRESPONDENCE_TASK_URL.INTAKE_TASK_URL.sub("uuid", correspondence.uuid)
    end
  end
end
