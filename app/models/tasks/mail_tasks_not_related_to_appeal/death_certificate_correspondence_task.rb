# frozen_string_literal: true

class DeathCertificateCorrespondenceTask < CorrespondenceMailTask
  def label
    COPY::DEATH_CERTIFICATE_MAIL_TASK_LABEL
  end
end