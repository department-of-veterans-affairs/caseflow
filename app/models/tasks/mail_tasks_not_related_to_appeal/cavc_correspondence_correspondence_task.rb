# frozen_string_literal: true

class CavcCorrespondenceCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end

  def task_url
    Constants.CORRESPONDENCE_TASK_URL.CORRESPONDENCE_TASK_DETAIL_URL.sub("uuid", correspondence.uuid)
  end
end