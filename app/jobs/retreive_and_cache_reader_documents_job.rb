# frozen_string_literal: true

class RetreiveAndCacheReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
  def perform; end
end
