# frozen_string_literal: true

class AutotaggedDocumentJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    return unless FeatureToggle.enabled?(:auto_tagging_ability)

    Document.where(auto_tagged: false).each do |doc|
      list_of_tags = ExternalApi::ClaimEvidenceService.get_key_phrases_from_document(doc.series_id)
      list_of_tags.each do |tag|
        new_tag = Tag.find_or_create_by(tag)
        begin
          doc.tags << new_tag
        rescue ActiveRecord::RecordNotUnique
          errors.push(new_tag.text => "This tag already exists for the document.")
        end
      end
    end
  end
end
