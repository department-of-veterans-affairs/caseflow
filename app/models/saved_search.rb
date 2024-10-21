# frozen_string_literal: true

class SavedSearch < CaseflowRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }
  validate :saved_search_limit

  scope :all_saved_searches, -> { order(created_at: :desc) }

  scope :my_saved_searches, ->(user) { where(user_id: user).order(created_at: :desc) }

  private

  def saved_search_limit
    fail(Caseflow::Error::MaximumSavedSearches) if user.saved_searches.count >= 10
  end
end
