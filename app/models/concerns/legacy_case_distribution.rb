module LegacyCaseDistribution
  extend ActiveSupport::Concern

  private

  def legacy_distribution
    rem = batch_size

    priority_hearing_appeals = docket.distribute_priority_appeals(judge,
                                                                  genpop: false,
                                                                  limit: rem)
    rem -= priority_hearing_appeals.count

    nonpriority_hearing_appeals = docket.distribute_nonpriority_appeals(judge,
                                                                        genpop: false,
                                                                        range: net_docket_range,
                                                                        limit: rem)
    rem -= nonpriority_hearing_appeals.count
    priority_rem = (priority_target - priority_hearing_appeals.count).clamp(0, rem)

    priority_nonhearing_appeals = docket.distribute_priority_appeals(judge,
                                                                     genpop: true,
                                                                     limit: priority_rem)
    rem -= priority_nonhearing_appeals.count

    nonpriority_appeals = docket.distribute_nonpriority_appeals(judge, limit: rem)

    [
      *priority_hearing_appeals, *nonpriority_hearing_appeals,
      *priority_nonhearing_appeals, *nonpriority_appeals
    ]
  end

  def docket
    @docket ||= LegacyDocket.new
  end

  def priority_count
    docket.count(priority: true, ready: true)
  end

  def net_docket_range
    [total_batch_size - priority_count, 0].max
  end

  def priority_target
    proportion = [1.0 * priority_count / total_batch_size, 1.0].min
    (proportion * batch_size).ceil
  end
end
