# frozen_string_literal: true

##
# Task to record on the appeal that a cavc extension request has been processed. Self completes upon creation.

class CavcExtensionRequestTask < Task
  validates :parent, presence: true, parentTask: { task_type: CavcRemandProcessedLetterResponseWindowTask }
  validates :assigned_by, :instructions, presence: true
  before_create :verify_user_organization
  after_create :completed!

  def self.label
    fail "subclass #{self} must implement label method"
  end

  private

  def verify_user_organization
    if !CavcLitigationSupport.singleton.user_has_access?(assigned_by)
      fail(Caseflow::Error::ActionForbiddenError,
           message: "Cavc extension requests can only be processed by the cavc litigation support team")
    end
  end
end
