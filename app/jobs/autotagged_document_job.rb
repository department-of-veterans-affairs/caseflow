# frozen_string_literal: true

class AutotaggedDocumentJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(doc_id = nil)
    return unless FeatureToggle.enabled?(:auto_tagging_ability)

    if doc_id.present?
      add_tags_to_doc(Document.find(doc_id))
    else
      Document.where(auto_tagged: false).each do |doc|
        add_tags_to_doc(doc)
        doc.update(auto_tagged: true)
      end
    end
  end

  private

  def add_tags_to_doc(doc)
    get_tags(doc).each do |tag_text|
      new_tag = find_existing_tag(tag_text) || Tag.find_or_create_by(tag_text)
      doc.tags << new_tag
    end
  end

  def get_tags(doc)
    ExternalApi::ClaimEvidenceService.get_key_phrases_from_document(doc.series_id)
  end

  def find_existing_tag(tag_text)
    Tag.find_by("lower(text) = ?", text.downcase)
  end
end
