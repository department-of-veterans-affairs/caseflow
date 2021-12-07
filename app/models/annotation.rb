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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: annotations
#
#  id            :integer          not null, primary key
#  comment       :string           not null
#  page          :integer
#  relevant_date :date
#  x             :integer
#  y             :integer
#  created_at    :datetime
#  updated_at    :datetime
#  document_id   :integer          not null, indexed
#  user_id       :integer          indexed
#
# Foreign Keys
#
#  fk_rails_4043df79bf  (user_id => users.id)
#
