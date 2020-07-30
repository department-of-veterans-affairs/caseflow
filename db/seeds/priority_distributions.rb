# frozen_string_literal: true

# create distribution seeds

module Seeds
  class PriorityDistributions < Base
    def seed!
      organize_judges
      create_previous_distribtions
      create_cases_tied_to_judges
      create_genpop_cases
      create_errorable_cases
    end

    private

    def organize_judges
      JudgeTeam.find_by(name: "BVAACTING").inactive!
      JudgeTeam.find_by(name: "BVAAWAKEFIELD").update!(accepts_priority_pushed_cases: false)
    end

    def create_previous_distribtions
      judges_with_previous_distributions.each do |judge|
        create_priority_distribution_this_month(judge)
        create_priority_distribution_this_month(judge)
        create_priority_distribution_last_month(judge)
        create_nonpriority_distribution_this_month(judge)
      end
    end

    def create_cases_tied_to_judges
      judges_with_tied_cases.each do |judge|
        create_legacy_cases_tied_to_judge(judge)
        create_hearing_cases_tied_to_judge(judge)
      end
    end

    def create_genpop_cases
      create_legacy_genpop_cases
      create_ama_hearing_genpop_cases
      create_direct_review_genpop_cases
      create_evidence_submission_genpop_cases
    end

    def create_errorable_cases
      create_legacy_appeal_with_previous_distribution
    end

    def create_legacy_cases_tied_to_judge(judge)
      create_legacy_ready_priority_cases_tied_to_judge(judge)
      create_legacy_nonready_priority_cases_tied_to_judge(judge)
      create_legacy_ready_nonpriority_cases_tied_to_judge(judge)
    end

    def create_hearing_cases_tied_to_judge(judge)
      create_hearing_ready_priority_cases_tied_to_judge(judge)
      create_hearing_nonready_priority_cases_tied_to_judge(judge)
      create_hearing_ready_nonpriority_cases_tied_to_judge(judge)
    end

    def create_nonready_priority_genpop_cases
      create_legacy_nonready_priority_genpop_cases
      create_ama_hearing_nonready_priority_genpop_cases
      create_direct_review_nonready_priority_genpop_cases
      create_evidence_submission_nonready_priority_genpop_cases
    end

    def create_legacy_genpop_cases
      create_legacy_ready_priority_genpop_cases
      create_legacy_ready_nonpriority_genpop_cases
      create_legacy_nonready_priority_genpop_cases
    end

    def create_ama_hearing_genpop_cases
      create_ama_hearing_ready_priority_genpop_cases
      create_ama_hearing_ready_nonpriority_genpop_cases
      create_ama_hearing_nonready_priority_genpop_cases
    end

    def create_direct_review_genpop_cases
      create_direct_review_ready_priority_genpop_cases
      create_direct_review_ready_nonpriority_genpop_cases
      create_direct_review_nonready_priority_genpop_cases
    end

    def create_evidence_submission_genpop_cases
      create_evidence_submission_ready_priority_genpop_cases
      create_evidence_submission_ready_nonpriority_genpop_cases
      create_evidence_submission_nonready_priority_genpop_cases
    end

    def create_priority_distribution_this_month(judge)
      build(
        :distribution,
        :priority,
        :completed,
        :this_month,
        judge: judge,
        statistics: { "batch_size" => rand(10) }
      ).save(validate: false)
    end

    def create_priority_distribution_last_month(judge)
      build(
        :distribution,
        :priority,
        :completed,
        :last_month,
        judge: judge,
        statistics: { "batch_size" => rand(10) }
      ).save(validate: false)
    end

    def create_nonpriority_distribution_this_month(judge)
      build(
        :distribution,
        :completed,
        :this_month,
        judge: judge,
        statistics: { "batch_size" => rand(10) }
      ).save(validate: false)
    end

    def create_legacy_ready_priority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :case,
          :aod,
          :ready_for_distribution,
          :tied_to_judge,
          tied_judge: judge,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_legacy_nonready_priority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :case,
          :aod,
          :tied_to_judge,
          tied_judge: judge,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_legacy_ready_nonpriority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :case,
          :ready_for_distribution,
          :tied_to_judge,
          tied_judge: judge,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_hearing_ready_priority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          :tied_to_judge,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    def create_hearing_nonready_priority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :appeal,
          :hearing_docket,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          :tied_to_judge,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    def create_hearing_ready_nonpriority_cases_tied_to_judge(judge)
      rand(5).times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :held_hearing,
          :tied_to_judge,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    def create_legacy_ready_priority_genpop_cases
      rand(50).times do
        create(
          :case,
          :aod,
          :ready_for_distribution,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_legacy_nonready_priority_genpop_cases
      rand(5).times do
        create(
          :case,
          :aod,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_legacy_ready_nonpriority_genpop_cases
      rand(5).times do
        create(
          :case,
          :ready_for_distribution,
          bfkey: random_key,
          correspondent: create(:correspondent, stafkey: random_key)
        )
      end
    end

    def create_ama_hearing_ready_priority_genpop_cases
      rand(50).times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          adding_user: User.first
        )
      end
    end

    def create_ama_hearing_nonready_priority_genpop_cases
      rand(5).times do
        create(
          :appeal,
          :hearing_docket,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          adding_user: User.first
        )
      end
    end

    def create_ama_hearing_ready_nonpriority_genpop_cases
      rand(5).times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :held_hearing,
          adding_user: User.first
        )
      end
    end

    def create_direct_review_ready_priority_genpop_cases
      rand(50).times do
        create(
          :appeal,
          :direct_review_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age
        )
      end
    end

    def create_direct_review_nonready_priority_genpop_cases
      rand(5).times do
        create(
          :appeal,
          :direct_review_docket,
          :advanced_on_docket_due_to_age
        )
      end
    end

    def create_direct_review_ready_nonpriority_genpop_cases
      rand(5).times do
        create(
          :appeal,
          :direct_review_docket,
          :ready_for_distribution
        )
      end
    end

    def create_evidence_submission_ready_priority_genpop_cases
      rand(50).times do
        create(
          :appeal,
          :evidence_submission_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age
        )
      end
    end

    def create_evidence_submission_nonready_priority_genpop_cases
      rand(50).times do
        create(
          :appeal,
          :evidence_submission_docket,
          :advanced_on_docket_due_to_age
        )
      end
    end

    def create_evidence_submission_ready_nonpriority_genpop_cases
      rand(50).times do
        create(
          :appeal,
          :evidence_submission_docket,
          :ready_for_distribution
        )
      end
    end

    def create_legacy_appeal_with_previous_distribution
      vacols_case = FactoryBot.create(
        :case,
        :aod,
        :ready_for_distribution,
        bfkey: random_key,
        correspondent: FactoryBot.create(:correspondent, stafkey: random_key)
      )
      FactoryBot.create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case)

      create_distribution_for_case_id(vacols_case.bfkey)
    end

    def create_distribution_for_case_id(case_id)
      distribution = FactoryBot.build(
        :distribution, :priority, :completed, :this_month, judge: User.third, statistics: { "batch_size" => rand(10) }
      )
      distribution.save!(validate: false)

      distribution.distributed_cases.create(
        case_id: vacols_case.bfkey,
        priority: case_id,
        docket: "legacy",
        ready_at: Time.zone.now,
        docket_index: "123",
        genpop: false,
        genpop_query: "any"
      )
    end

    def judges_with_tied_cases
      @judges_with_tied_cases ||= begin
        JudgeTeam.unscoped.map(&:judge).unshift(User.find_by(full_name: "Steve Attorney_Cases Casper"))
      end
    end

    def judges_with_previous_distributions
      @judges_with_previous_distributions ||= begin
        JudgeTeam.unscoped.map(&:judge).unshift(User.find_by(full_name: "Keith Judge_CaseToAssign_NoTeam Keeling"))
      end
    end

    def random_key
      rand.to_s[2..11]
    end
  end
end
