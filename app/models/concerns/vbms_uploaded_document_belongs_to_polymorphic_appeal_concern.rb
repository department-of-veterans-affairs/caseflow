# frozen_string_literal: true

module VbmsUploadedDocumentBelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern
  include DecisionReviewPolymorphicHelper

  included do
    define_polymorphic_decision_review_associations(:appeal, :vbms_uploaded_documents, %w[Appeal LegacyAppeal])
  end
end
