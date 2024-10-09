class SavedSearch < CaseflowRecord
  belongs_to :user

  validates :search_name, presence: true, length: { maximum: 255 }
  validates :search_description, presence: true, length: { maximum: 1000 }
  validate :saved_search_limit

  private

  def saved_search_limit
    fail(Caseflow::Error::MaximunSavedSearches) if user.saved_searches.count >= 10
  end
end
