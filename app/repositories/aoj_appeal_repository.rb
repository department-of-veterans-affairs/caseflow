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

    def nod_count
      MetricsService.record("VACOLS: nod_count",
                            name: "nod_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.nod_count
      end
    end

    def regular_non_aod_docket_count
      MetricsService.record("VACOLS: regular_non_aod_docket_count",
                            name: "regular_non_aod_docket_count",
                            service: :vacols) do
        VACOLS::AojCaseDocket.regular_non_aod_docket_count
      end
    end

    def latest_docket_month
      result = MetricsService.record("VACOLS: latest_docket_month",
                                     name: "latest_docket_month",
                                     service: :vacols) do
        VACOLS::AojCaseDocket.docket_date_of_nth_appeal_in_case_storage(7000)
      end

      result.beginning_of_month
    end

    def docket_counts_by_month
      MetricsService.record("VACOLS: docket_counts_by_month",
                            name: "docket_counts_by_month",
                            service: :vacols) do
        VACOLS::AojCaseDocket.docket_counts_by_month
      end
    end

    def age_of_n_oldest_genpop_priority_appeals(num)
      MetricsService.record("VACOLS: age_of_n_oldest_genpop_priority_appeals",
                            name: "age_of_n_oldest_genpop_priority_appeals",
                            service: :vacols) do
        VACOLS::AojCaseDocket.age_of_n_oldest_genpop_priority_appeals(num)
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

    def nonpriority_decisions_per_year
      MetricsService.record("VACOLS: nonpriority_decisions_per_year",
                            name: "nonpriority_decisions_per_year",
                            service: :vacols) do
        VACOLS::AojCaseDocket.nonpriority_decisions_per_year
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

    private

    # NOTE: this should be called within a transaction where you are closing an appeal
    def close_associated_hearings(case_record)
      # Only scheduled hearings need to be closed
      case_record.case_hearings.where(clsdate: nil, hearing_disp: nil).update_all(
        clsdate: VacolsHelper.local_time_with_utc_timezone,
        hearing_disp: VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled]
      )
    end

    # NOTE: this should be called within a transaction where you are closing an appeal
    def close_associated_diary_notes(case_record, user)
      case_record.notes.where(tskdcls: nil).update_all(
        tskdcls: VacolsHelper.local_time_with_utc_timezone,
        tskmdtm: VacolsHelper.local_time_with_utc_timezone,
        tskmdusr: user.regional_office,
        tskstat: "C"
      )
    end
  end
  # :nocov:
  # rubocop:enable Metrics/ClassLength
end
