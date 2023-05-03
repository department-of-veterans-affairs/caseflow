# frozen_string_literal: true

class AutoTagReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform
    MetricsService.record("Auto tagging Recently Created Documents records",
                          service: :reader,
                          name: "job.reader.documents.auto.tagging") do
      Document.where("created_at < ?", 1.day.ago.to_date).each do |document|
        auto_tag(document)
      end
    end
  end

  private

  def auto_tag(document)
    MetricsService.record("Auto tagging Document with id #{document.id}",
      service: :queue,
      name: "job.reader.documents.auto.tagging") do
        tags = document.auto_tag
        log_info(document, tags)
    end
  end

  def log_info(document, tags)
    Rails.logger.info log_message(document, tags)
  end

  def log_message(document, tags)
    "AutoTagReaderDocumentsJob - " \
    "Document Inspect: (#{document.inspect}) - " \
    "Tags Count: (#{tags.count}) - " \
    "Tags Inspect: (#{tags.map(&:inspect)})"
  end
end
