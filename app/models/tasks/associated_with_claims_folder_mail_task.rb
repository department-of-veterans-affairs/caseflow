# frozen_string_literal: true

class AssociatedWithClaimsFolderMailTask < MailTask
  def self.label
    COPY::ASSOCIATED_WITH_CLAIMS_FOLDER_MAIL_TASK_LABEL
  end
end
