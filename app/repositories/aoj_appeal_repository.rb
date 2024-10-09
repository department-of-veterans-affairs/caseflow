# frozen_string_literal: true

class AojAppealRepository < AppealRepository
  # :nocov:

  class << self
    def docket_counts_by_priority_and_readiness
      MetricsService.record("VACOLS: docket_counts_by_priority_and_readiness",
                            name: "docket_counts_by_priority_and_readiness",
                            service: :vacols) do
        VACOLS::AojCaseDocket.counts_by_priority_and_readiness
      end
    end

    def genpop_priority_count
      MetricsService.record("VACOLS: genpop_priority_count",
                            name: "genpop_priority_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.genpop_priority_count
      end
    end

    def not_genpop_priority_count
      MetricsService.record("VACOLS: not_genpop_priority_count",
                            name: "not_genpop_priority_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.not_genpop_priority_count
      end
    end

    def priority_ready_appeal_vacols_ids
      MetricsService.record("VACOLS: priority_ready_appeal_vacols_ids",
                            name: "priority_ready_appeal_vacols_ids",
                            service: :vacols) do
        VACOLS::AojCaseDocket.priority_ready_appeal_vacols_ids
      end
    end

    def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
      MetricsService.record("VACOLS: age_of_n_oldest_nonpriority_appeals_available_to_judge",
                            name: "age_of_n_oldest_nonpriority_appeals_available_to_judge",
                            service: :vacols) do
        VACOLS::AojCaseDocket.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
      end
    end

    def age_of_oldest_priority_appeal
      MetricsService.record("VACOLS: age_of_oldest_priority_appeal",
                            name: "age_of_oldest_priority_appeal",
                            service: :vacols) do
        VACOLS::AojCaseDocket.age_of_oldest_priority_appeal
      end
    end

    def age_of_oldest_priority_appeal_by_docket_date
      MetricsService.record("VACOLS: age_of_oldest_priority_appeal",
                            name: "age_of_oldest_priority_appeal",
                            service: :vacols) do
        VACOLS::AojCaseDocket.age_of_oldest_priority_appeal_by_docket_date
      end
    end

    def age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
      MetricsService.record("VACOLS: age_of_n_oldest_priority_appeals_available_to_judge",
                            name: "age_of_n_oldest_priority_appeals_available_to_judge",
                            service: :vacols) do
        VACOLS::AojCaseDocket.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
      end
    end

    def distribute_priority_appeals(judge, genpop, limit)
      MetricsService.record("VACOLS: distribute_priority_appeals",
                            name: "distribute_priority_appeals",
                            service: :vacols) do
        VACOLS::AojCaseDocket.distribute_priority_appeals(judge, genpop, limit)
      end
    end

    def distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog)
      MetricsService.record("VACOLS: distribute_nonpriority_appeals",
                            name: "distribute_nonpriority_appeals",
                            service: :vacols) do
        VACOLS::AojCaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog)
      end
    end

    def ready_to_distribute_appeals
      MetricsService.record("VACOLS: ready_to_distribute_appeals",
                            name: "ready_to_distribute_appeals",
                            service: :vacols) do
        VACOLS::AojCaseDocket.ready_to_distribute_appeals
      end
    end

    def priority_appeals_affinity_date_count(in_window)
      MetricsService.record("VACOLS: priority_appeals_affinity_date_count",
                            name: "priority_appeals_affinity_date_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.priority_appeals_affinity_date_count(in_window)
      end
    end

    def non_priority_appeals_affinity_date_count(in_window)
      MetricsService.record("VACOLS: non_priority_appeals_affinity_date_count",
                            name: "non_priority_appeals_affinity_date_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.non_priority_appeals_affinity_date_count(in_window)
      end
    end

    def appeals_tied_to_non_ssc_avljs
      MetricsService.record("VACOLS: appeals_tied_to_non_ssc_avljs",
                            name: "appeals_tied_to_non_ssc_avljs",
                            service: :vacols) do
        VACOLS::AojCaseDocket.appeals_tied_to_non_ssc_avljs
      end
    end
  end
  # :nocov:
end
