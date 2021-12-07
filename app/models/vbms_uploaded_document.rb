# frozen_string_literal: true

class VbmsUploadedDocument < CaseflowRecord
  include HasAppealUpdatedSince

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal

  validates :document_type, presence: true

  attribute :file, :string

  def cache_file
    UploadDocumentToVbms.new(document: self).cache_file
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: vbms_uploaded_documents
#
#  id                  :bigint           not null, primary key
#  appeal_type         :string           not null, indexed => [appeal_id]
#  attempted_at        :datetime
#  canceled_at         :datetime
#  document_type       :string           not null
#  error               :string
#  last_submitted_at   :datetime
#  processed_at        :datetime
#  submitted_at        :datetime
#  uploaded_to_vbms_at :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null, indexed
#  appeal_id           :bigint           not null, indexed, indexed => [appeal_type]
#
