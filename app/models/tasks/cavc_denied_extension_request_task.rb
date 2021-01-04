# frozen_string_literal: true

##
# Task to record on the appeal that a cavc extension request has been denied. Self completes upon creation.

class CavcDeniedExtensionRequestTask < CavcExtensionRequestTask
  def self.label
    COPY::CAVC_DENIED_EXTENSION_TASK_LABEL
  end
end
