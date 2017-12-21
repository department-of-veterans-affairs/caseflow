class Annotation < ActiveRecord::Base
  belongs_to :document
  belongs_to :user
  validates :comment, presence: true

  def to_hash
    serializable_hash(
      methods: [:document_id, :comment, :x, :y, :page, :relevant_date]
    )
  end
end
