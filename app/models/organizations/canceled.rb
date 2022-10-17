# frozen_string_literal: true

class Canceled < Organization
  def tasks_url
      "/decision_reviews/#{url}"
  end
end
