module LegacyCaseDistribution
  extend ActiveSupport::Concern

  private

  def legacy_distribution
    rem = batch_size
    priority_target = target_number_of_priority_appeals

    priority_hearing_appeals = docket.distribute_priority_appeals(self, genpop: "not_genpop", limit: rem)
    rem -= priority_hearing_appeals.count

    nonpriority_hearing_appeals = docket.distribute_nonpriority_appeals(self,
                                                                        genpop: "not_genpop",
                                                                        range: net_docket_range,
                                                                        limit: rem)
    rem -= nonpriority_hearing_appeals.count

    if priority_hearing_appeals.count < priority_target
      priority_rem = [priority_target - priority_hearing_appeals.count, rem].min

      priority_nonhearing_appeals = docket.distribute_priority_appeals(self,
                                                                       genpop: "only_genpop",
                                                                       limit: priority_rem)
      rem -= priority_nonhearing_appeals.count
    end

    nonpriority_appeals = docket.distribute_nonpriority_appeals(self, limit: rem)

    [*priority_hearing_appeals, *nonpriority_hearing_appeals, *priority_nonhearing_appeals, *nonpriority_appeals]
  end

  # def legacy_hearing_only_distribution
  #   rem = batch_size

  #   priority_appeals = docket.distribute_priority_appeals(self, genpop: "not_genpop", limit: rem)
  #   rem -= priority_appeals.count

  #   nonpriority_appeals = docket.distribute_nonpriority_appeals(self, genpop: "not_genpop", range: 7000, limit: rem)

  #   [*priority_appeals, *nonpriority_appeals]
  # end

  def legacy_statistics
    {
      batch_size: batch_size,
      total_batch_size: total_batch_size,
      priority_count: legacy_priority_count
    }
  end

  def docket
    @docket ||= LegacyDocket.new
  end

  def legacy_priority_count
    docket.count(priority: true, ready: true)
  end

  def net_docket_range
    [total_batch_size - legacy_priority_count, 0].max
  end

  def target_number_of_priority_appeals
    proportion = [legacy_priority_count.to_f / total_batch_size, 1.0].min
    (proportion * batch_size).ceil
  end
end
