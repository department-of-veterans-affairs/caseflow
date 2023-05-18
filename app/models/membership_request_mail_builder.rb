# frozen_string_literal: true

class MembershipRequestMailBuilder
  def send_email_after_creation
    fail NotImplementedError, "Subclasses must implement this method"
  end

  def send_email_request_approved
    fail NotImplementedError, "Subclasses must implement this method"
  end

  def send_email_request_denied
    fail NotImplementedError, "Subclasses must implement this method"
  end

  def send_email_request_cancelled
    fail NotImplementedError, "Subclasses must implement this method"
  end
end
