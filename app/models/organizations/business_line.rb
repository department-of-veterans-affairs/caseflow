class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end
end
