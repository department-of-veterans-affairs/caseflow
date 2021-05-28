# frozen_string_literal: true

class NonratingRequestIssue < RequestIssue
  def rating?
    false
  end

  def nonrating?
    true
  end
end
