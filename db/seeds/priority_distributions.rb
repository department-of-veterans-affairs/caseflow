# frozen_string_literal: true

# Create distribution seeds to test priority push case distribution job.
# Mocks previously distributed cases for judges. Sets up cases ready to be distributed.
# Invoke with:
# RequestStore[:current_user] = User.system_user
# Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
# Seeds::PriorityDistributions.new.seed!
#
# Creates 300+ priority cases ready for distribution
# Warning a number are not setup correctly so cannot be used beyond
# just distributing

module Seeds
  class PriorityDistributions < Base # rubocop:disable Metrics/ClassLength
    # :nocov:
    def initialize
      @ready_nonpriority_hearing_case_count = 0
      initial_file_number_and_participant_id
    end

    def seed!
      # organize_judges
      create_previous_distribtions
      create_cases_tied_to_judges
      create_genpop_cases
      create_errorable_cases
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 200_000_000
      @participant_id ||= 600_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 1000
        @participant_id += 1000
      end
    end

    def create_veteran
      @file_number += 1
      @participant_id += 1
      create(
        :veteran,
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      )
    end

    # Without context, this method doesn't make any useful changes to the seed data so I'm not running it
    def organize_judges
      JudgeTeam.unscoped.find_by(name: "BVAACTING").inactive!
      JudgeTeam.find_by(name: "BVAAWAKEFIELD").update!(accepts_priority_pushed_cases: false)
    end

    def create_previous_distribtions
      judges_with_previous_distributions.each do |judge|
        2.times { create_priority_distribution_this_month(judge) }
        create_priority_distribution_last_month(judge)
        create_nonpriority_distribution_this_month(judge)
      end
    end

    def create_cases_tied_to_judges
      judges_with_tied_cases.each do |judge|
        create_legacy_cases_tied_to_judge(judge)
        create_hearing_cases_tied_to_judge(judge)
      end
      judges_with_tied_cases.first(5).each do |judge|
        create_extra_ready_hearing_nonpriority_case_for_judge(judge)
      end
    end

    def create_genpop_cases
      create_legacy_genpop_cases
      create_ama_hearing_genpop_cases
      create_direct_review_genpop_cases
      create_evidence_submission_genpop_cases
      create_cavc_genpop_cases
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

    def create_legacy_genpop_cases
      create_legacy_ready_priority_genpop_cases
      create_legacy_ready_nonpriority_genpop_cases
      create_legacy_nonready_priority_genpop_cases
    end

    def create_ama_hearing_genpop_cases
      create_ama_hearing_ready_priority_genpop_cases
      create_ama_hearing_ready_nonpriority_genpop_cases
      create_ama_hearing_ready_nonpriority_genpop_cases_ready_61_days_ago
      create_ama_hearing_ready_nonpriority_genpop_cases_ready_15_days_ago
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

    def create_cavc_genpop_cases
      create_ready_cavc_genpop_cases
      create_ready_cavc_aod_genpop_cases
      create_ready_cavc_genpop_cases_within_affinity_lever
      create_ready_cavc_genpop_cases_outside_of_affinity_lever
      create_nonready_cavc_genpop_cases
    end

    def create_priority_distribution_this_month(judge)
      create_unvalidated_completed_distribution(
        traits: [:priority, :this_month],
        judge: judge,
        statistics: { "batch_size" => 4 }
      )
    end

    def create_priority_distribution_last_month(judge)
      create_unvalidated_completed_distribution(
        traits: [:priority, :last_month],
        judge: judge,
        statistics: { "batch_size" => 4 }
      )
    end

    def create_nonpriority_distribution_this_month(judge)
      create_unvalidated_completed_distribution(
        traits: [:this_month],
        judge: judge,
        statistics: { "batch_size" => 4 }
      )
    end

    def create_legacy_ready_priority_cases_tied_to_judge(judge)
      2.times do |num|
        create(
          :case,
          :aod,
          :ready_for_distribution,
          :tied_to_judge,
          :type_original,
          tied_judge: judge,
          bfd19: 1.year.ago.to_date - num.weeks,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_legacy_nonready_priority_cases_tied_to_judge(judge)
      2.times do
        create(
          :case,
          :aod,
          :tied_to_judge,
          :type_original,
          tied_judge: judge,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_legacy_ready_nonpriority_cases_tied_to_judge(judge)
      2.times do |num|
        create(
          :case,
          :ready_for_distribution,
          :tied_to_judge,
          :type_original,
          tied_judge: judge,
          bfd19: 1.year.ago.to_date - num.weeks,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_hearing_ready_priority_cases_tied_to_judge(judge)
      4.times do |num|
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing_and_ready_to_distribute,
          :tied_to_judge,
          veteran: create_veteran,
          receipt_date: num.weeks.ago,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    def create_hearing_nonready_priority_cases_tied_to_judge(judge)
      4.times do |num|
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          :tied_to_judge,
          veteran: create_veteran,
          receipt_date: num.weeks.ago,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    def create_hearing_ready_nonpriority_cases_tied_to_judge(judge)
      2.times do
        @ready_nonpriority_hearing_case_count += 1
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :held_hearing_and_ready_to_distribute,
          :tied_to_judge,
          veteran: create_veteran,
          receipt_date: @ready_nonpriority_hearing_case_count.days.ago,
          tied_judge: judge,
          adding_user: User.first
        )
      end
    end

    # create one extra hearing per judge for testing ACD changes
    def create_extra_ready_hearing_nonpriority_case_for_judge(judge)
      create(
        :appeal,
        :hearing_docket,
        :with_post_intake_tasks,
        :held_hearing_and_ready_to_distribute,
        :tied_to_judge,
        veteran: create_veteran,
        receipt_date: 4.months.ago,
        tied_judge: judge,
        adding_user: User.first
      )
    end

    def create_legacy_ready_priority_genpop_cases
      20.times do |num|
        create(
          :case,
          :aod,
          :ready_for_distribution,
          :type_original,
          bfd19: 1.year.ago.to_date - num.days,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_legacy_nonready_priority_genpop_cases
      2.times do
        create(
          :case,
          :aod,
          :type_original,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_legacy_ready_nonpriority_genpop_cases
      20.times do |num|
        create(
          :case,
          :ready_for_distribution,
          :type_original,
          bfd19: 1.year.ago.to_date - num.days,
          correspondent: create(:correspondent)
        )
      end
    end

    def create_ama_hearing_ready_priority_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing_and_ready_to_distribute,
          veteran: create_veteran,
          receipt_date: num.days.ago,
          adding_user: User.first
        )
      end
    end

    def create_ama_hearing_nonready_priority_genpop_cases
      4.times do |num|
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          veteran: create_veteran,
          receipt_date: num.weeks.ago,
          adding_user: User.first
        )
      end
    end

    def create_ama_hearing_ready_nonpriority_genpop_cases
      2.times do
        @ready_nonpriority_hearing_case_count += 1
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :held_hearing_and_ready_to_distribute,
          veteran: create_veteran,
          receipt_date: @ready_nonpriority_hearing_case_count.days.ago,
          adding_user: User.first
        )
      end
    end

    # creates a hearing case with dates specifically requested during ACD algorithm changes
    # Appeal received 92 days ago, hearing tasks complete and ready to distribute 61 days ago
    def create_ama_hearing_ready_nonpriority_genpop_cases_ready_61_days_ago
      Timecop.travel(95.days.ago)
      2.times do
        appeal = create(:appeal,
                        :hearing_docket,
                        :with_post_intake_tasks,
                        :held_hearing_and_ready_to_distribute,
                        veteran: create_veteran,
                        adding_user: User.first)
        tasks = appeal.tasks
        [:TranscriptionTask, :EvidenceSubmissionWindowTask, :AssignHearingDispositionTask].each do |type|
          date = 30.days.from_now
          tasks.find_by(type: type).update!(
            created_at: date, assigned_at: date, closed_at: date, updated_at: date
          )
        end

        tasks.find_by(type: :HearingTask).update!(closed_at: 30.days.from_now)
        tasks.find_by(type: :DistributionTask).update!(assigned_at: 30.days.from_now)
      end
      Timecop.return
    end

    # creates a hearing case with dates specifically requested during ACD algorithm changes
    # Appeal received 95 days ago, hearing held 65 days ago,
    # evidence window completed over 64 days ago,ready for dist 18 days ago
    def create_ama_hearing_ready_nonpriority_genpop_cases_ready_15_days_ago
      Timecop.travel(95.days.ago)
      2.times do
        appeal = create(:appeal,
                        :hearing_docket,
                        :with_post_intake_tasks,
                        :held_hearing_and_ready_to_distribute,
                        veteran: create_veteran,
                        adding_user: User.first)
        tasks = appeal.tasks

        tasks.find_by(type: :TranscriptionTask).update!(created_at: 30.days.from_now,
                                                        assigned_at: 30.days.from_now,
                                                        closed_at: 77.days.from_now,
                                                        updated_at: 77.days.from_now)

        tasks.find_by(type: :EvidenceSubmissionWindowTask).update!(created_at: 30.days.from_now,
                                                                   assigned_at: 30.days.from_now,
                                                                   closed_at: 31.days.from_now,
                                                                   updated_at: 31.days.from_now)

        tasks.find_by(type: :AssignHearingDispositionTask).update!(created_at: Time.zone.now,
                                                                   assigned_at: Time.zone.now,
                                                                   closed_at: 77.days.from_now,
                                                                   updated_at: 77.days.from_now)
        tasks.find_by(type: :HearingTask).update!(closed_at: 77.days.from_now)
        tasks.find_by(type: :DistributionTask).update!(assigned_at: 77.days.from_now)
      end
      Timecop.return
    end

    def create_direct_review_ready_priority_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :direct_review_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_direct_review_nonready_priority_genpop_cases
      2.times do |num|
        create(
          :appeal,
          :direct_review_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_direct_review_ready_nonpriority_genpop_cases
      2.times do |num|
        create(
          :appeal,
          :direct_review_docket,
          :ready_for_distribution,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_evidence_submission_ready_priority_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :evidence_submission_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_evidence_submission_nonready_priority_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :evidence_submission_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_evidence_submission_ready_nonpriority_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :evidence_submission_docket,
          :ready_for_distribution,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_ready_cavc_genpop_cases
      4.times do |num|
        create(
          :appeal,
          :type_cavc_remand,
          :cavc_ready_for_distribution,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_ready_cavc_aod_genpop_cases
      4.times do |num|
        create(
          :appeal,
          :type_cavc_remand,
          :cavc_ready_for_distribution,
          :advanced_on_docket_due_to_age,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    # 5 cases to test removal of cavc affinity lever in by_docket_date
    # the interaction of appeal and cavc_remand factory isn't very clear, so use Timecop to set receipt date
    def create_ready_cavc_genpop_cases_within_affinity_lever
      Timecop.travel(14.days.ago)
      4.times do
        create(
          :appeal,
          :direct_review_docket,
          :type_cavc_remand,
          :cavc_ready_for_distribution,
          veteran: create_veteran
        )
      end
      Timecop.return
    end

    def create_ready_cavc_genpop_cases_outside_of_affinity_lever
      Timecop.travel(28.days.ago)
      4.times do
        create(
          :appeal,
          :direct_review_docket,
          :type_cavc_remand,
          :cavc_ready_for_distribution,
          veteran: create_veteran
        )
      end
      Timecop.return
    end

    def create_nonready_cavc_genpop_cases
      20.times do |num|
        create(
          :appeal,
          :type_cavc_remand,
          veteran: create_veteran,
          receipt_date: num.days.ago
        )
      end
    end

    def create_legacy_appeal_with_previous_distribution
      vacols_case = create(
        :case,
        :aod,
        :ready_for_distribution,
        :type_original,
        correspondent: create(:correspondent)
      )
      create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case)
      create_distribution_for_case_id(vacols_case.bfkey)
    end

    def create_distribution_for_case_id(case_id)
      create_unvalidated_completed_distribution(
        traits: [:priority, :completed, :this_month],
        judge: User.third,
        statistics: { "batch_size" => 4 }
      ).distributed_cases.create(
        case_id: case_id,
        priority: case_id,
        docket: "legacy",
        ready_at: Time.zone.now,
        docket_index: "123",
        genpop: false,
        genpop_query: "any"
      )
    end

    def create_unvalidated_completed_distribution(attrs = {})
      distribution = FactoryBot.build(:distribution, *attrs.delete(:traits), attrs)
      distribution.save!(validate: false)
      distribution.completed!
      distribution
    end

    def judges_with_tied_cases
      @judges_with_tied_cases ||= begin
        judges_with_judge_teams.unshift(User.find_by(full_name: "Steve Attorney_Cases Casper"))
      end
    end

    def judges_with_previous_distributions
      @judges_with_previous_distributions ||= begin
        judges_with_judge_teams.unshift(User.find_by(full_name: "Keith Judge_CaseToAssign_NoTeam Keeling"))
      end
    end

    def judges_with_judge_teams
      JudgeTeam.pushed_priority_cases_allowed.map(&:judge)
    end
    # :nocov:
  end
end
