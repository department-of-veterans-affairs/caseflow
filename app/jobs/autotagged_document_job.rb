# frozen_string_literal: true

class AutotaggedDocumentJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    return unless FeatureToggle.enabled?(:auto_tagging_ability)

    document_ids_not_auto_tagged

    auto_tagged_document_ids.each do |id|
      key_phrases = ExternalApi::ClaimEvidenceService.get_key_phrases_from_document(:id)
      # 19824 card need to call here
    end

  end

  private

  def document_ids_not_auto_tagged
    Document.where(auto_tagged: false).pluck(:id)
  end

  def auto_tagged_document_ids
    Document.where(auto_tagged: true).pluck(:id)
  end
end
