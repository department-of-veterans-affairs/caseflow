# frozen_string_literal: true

class AutotaggedDocumentJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(doc_id = nil)
    return unless FeatureToggle.enabled?(:auto_tagging_ability)

    if doc_id.present?
      add_tags_to_doc(Document.find(doc_id))
    else
      Document.where(auto_tagged: false).each do |doc|
        begin
          add_tags_to_doc(doc)
        rescue StandardError => error
          Rails.logger.error(error.message)
          Raven.capture_exception(error.message)
          next
        end
      end
    end
  end

  private

  def add_tags_to_doc(doc)
    tags = get_tags(doc)
    return if tags.nil?

    tags.each do |tag_text|
      next if find_existing_tag(tag_text).present?

      new_tag = Tag.find_or_create_by(text: tag_text)
      doc.tags << new_tag
    end
    doc.update(auto_tagged: true)
  end

  def get_tags(doc)
    ExternalApi::ClaimEvidenceService.get_key_phrases_from_document(doc.series_id[1..-2])
  end

  def find_existing_tag(tag_text)
    Tag.find_by("lower(text) = ?", tag_text.downcase)
  end
end
