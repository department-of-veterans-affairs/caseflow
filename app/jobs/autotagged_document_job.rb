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
    begin
      doc.update(auto_tagged: true)
      tags = get_tags(doc)
      return if tags.nil?

      tags.each do |tag_text|
        existing_tag = find_existing_tag(tag_text)
        if existing_tag.present?
          next if doc.tags.include?(existing_tag)

          doc.tags << existing_tag
        else
          new_tag = Tag.find_or_create_by(text: tag_text)
          doc.tags << new_tag
        end
      end
    rescue StandardError => e
      doc.update(auto_tagged: false)
      raise if e.message == "no tags found"
    end
  end

  def get_tags(doc)
    tags = ExternalApi::ClaimEvidenceService.get_key_phrases_from_document(doc.series_id[1..-2])
    tags.uniq!(&:downcase)
    tags
  rescue StandardError
    raise StandardError, "no tags found"
  end

  def find_existing_tag(tag_text)
    Tag.where("text ilike ?", "%#{tag_text}%").first
  end
end
