# frozen_string_literal: true

##
# Task to record on the appeal that a cavc extension request has been granted. Self completes upon creation.

class CavcGrantedExtensionRequestTask < CavcExtensionRequestTask
  def self.label
    COPY::CAVC_GRANTED_EXTENSION_TASK_LABEL
  end
end
