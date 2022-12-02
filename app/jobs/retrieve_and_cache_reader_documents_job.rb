# frozen_string_literal: true

class RetrieveAndCacheReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
  def perform; end
end
