# frozen_string_literal: true

class Annotation < CaseflowRecord
  belongs_to :document
  belongs_to :user
  validates :comment, presence: true

  has_paper_trail save_changes: false, on: [:update, :destroy]

  def to_hash
    serializable_hash(
      methods: [:document_id, :comment, :x, :y, :page, :relevant_date]
    )
  end
end
