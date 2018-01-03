class RampIssue < ActiveRecord::Base
  belongs_to :review, polymorphic: true

  def contention=(contention)
    self.contention_reference_id = contention.id
    self.description = contention.text
  end
end
