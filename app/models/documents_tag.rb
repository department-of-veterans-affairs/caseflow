# frozen_string_literal: true

class DocumentsTag < CaseflowRecord
  belongs_to :document
  belongs_to :tag

  has_paper_trail save_changes: false, on: [:update, :destroy]
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: documents_tags
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  document_id :integer          not null, indexed => [tag_id]
#  tag_id      :integer          not null, indexed => [document_id]
#
