
class Annotation < ActiveRecord::Base
  belongs_to :document
  belongs_to :user
  validates :comment, presence: true

  has_paper_trail only: [:comment, :x, :y, :page, :relevant_date]

  def to_hash
    serializable_hash(
      methods: [:document_id, :comment, :x, :y, :page, :relevant_date]
    )
  end
end
