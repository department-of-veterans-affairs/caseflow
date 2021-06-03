# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.hearing
  end

  def ready_priority_appeals
    appeals(priority: true, ready: true)
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    ready_priority_appeals.limit(num).map(&:ready_for_distribution_at)
  end

  # Hearing cases distinguish genpop from cases tied to a judge
  def genpop_priority_count
    ready_priority_appeals.count
  end

  # "genpop" attribute is unused because all Hearing Request docket appeals are "genpop". Leaving
  # "genpop" attribute in the function signature for compatibility with other Dockets.
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1)
    appeals = appeals(priority: priority, ready: true).limit(limit)

    HearingRequestCaseDistributor.new(
      appeals: appeals, distribution: distribution, priority: priority
    ).call
  end
end
