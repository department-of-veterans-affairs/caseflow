# frozen_string_literal: true

class CorrespondenceMailTask::AssociatedWithClaimsFolderMailTask < CorrespondenceMailTask
  def self.label
    COPY::ASSOCIATED_WITH_CLAIMS_FOLDER_MAIL_TASK_LABEL
  end
end
