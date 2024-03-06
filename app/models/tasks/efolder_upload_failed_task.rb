# frozen_string_literal: true

class EfolderUploadFailedTask < CorrespondenceTask
  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REVIEW_PACKAGE_TASK_URL.sub("uuid", correspondence.uuid)
  end
end
