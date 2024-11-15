# frozen_string_literal: true

# This seed creates ~100 appeals which have an affinity to a judge based case distribution algorithm levers,
# and ~100 appeals which are similar but fall just outside of the affinity day levers and will be distributed
# to any judge. Used primarily in testing APPEALS-36998 and other ACD feature work
module Seeds
  class AmaAffinityCases < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_file_number_and_participant_id
    end

    def seed!
      create_cda_admin_user
      create_priority_affinity_cases
      create_nonpriority_affinity_cases
      create_set_of_affinity_cases
      create_hearing_docket_cavc_cases
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 510_000_000
      @participant_id ||= 910_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 1000
        @participant_id += 1000
      end
    end

    def create_veteran
      @file_number += 1
      @participant_id += 1

      Veteran.find_by_participant_id(@participant_id) || create(
        :veteran,
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      )
    end

    def find_or_create_active_cda_admin_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :admin_intake_role, :cda_control_admin, :bva_intake_admin, :team_admin,
               :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def create_cda_admin_user
      judge = find_or_create_active_cda_admin_judge("QAACDPlus1","QA_Admin1 ACD_CF TM_Mgmt_Intake")
      judge_team = JudgeTeam.for_judge(judge)
      user = User.find_by_css_id("BVASCASPER1")
      judge_team.add_user(user)
    end

    def create_priority_affinity_cases
      judges_with_attorneys.each do |judge|
        2.times do
          create_case_ready_for_less_than_cavc_affinty_days(judge)
          create_case_ready_for_less_than_aod_hearing_affinity_days(judge)
          create_case_ready_for_more_than_cavc_affinty_days(judge)
          create_case_ready_for_more_than_aod_hearing_affinity_days(judge)
        end
      end
    end

    def create_nonpriority_affinity_cases
      judges_with_attorneys.each do |judge|
        2.times do
          create_case_ready_for_less_than_hearing_affinity_days(judge)
          create_case_ready_for_more_than_hearing_affinity_days(judge)
        end
      end
    end

    def create_set_of_affinity_cases
      judges_with_attorneys.each do |judge|
        create_ama_affinity_cases_set(judge, (4.years + 1.week))
        create_ama_affinity_cases_set(judge, 3.years)
      end
      2.times do
        create_ama_affinity_cases_set(User.find_by_css_id("BVABDANIEL"), 1.year)
      end
    end

    def create_hearing_docket_cavc_cases
      judges_with_attorneys.each do |judge|
        # Case in affinity window for both levers where new hearing and previous deciding judge are the same
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: judge,
                                                     days_ago:CaseDistributionLever.cavc_affinity_days - 7)
        # Case with affinity between the two levers where new hearing and previous deciding judge are the same
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: judge,
                                                     days_ago:CaseDistributionLever.ama_hearing_case_affinity_days - 7)
        # Case outside of affinity window for both levers where new hearing and previous deciding judge are the same
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: judge,
                                                     days_ago:CaseDistributionLever.ama_hearing_case_affinity_days + 7)

        # Case in affinity window for both levers where new hearing and previous deciding judge are different
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: hearing_judge,
                                                     days_ago:CaseDistributionLever.cavc_affinity_days - 7)
        # Case with affinity between the two levers where new hearing and previous deciding judge are different
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: hearing_judge,
                                                     days_ago:CaseDistributionLever.ama_hearing_case_affinity_days - 7)
        # Case outside of affinity window for both levers where new hearing and previous deciding judge are different\
        create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge: judge, hearing_judge: hearing_judge,
                                                     days_ago:CaseDistributionLever.ama_hearing_case_affinity_days + 7)
      end
    end

    def judges_with_attorneys
      # use judges with attorneys to minimize how many cases are distributed when testing because the
      # alternative_batch_size is higher than the batch_size for most judge teams
      @judges_with_attorneys ||=
        JudgeTeam.all.reject { |jt| jt.attorneys.empty? }.map(&:judge).compact.filter(&:vacols_attorney_id)
    end

    def hearing_judge
      @hearing_judge ||= User.find_by_css_id("HRNG_JUDGE") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "HRNG_JUDGE", full_name: "Judge HeldHearing")
    end

    # rubocop:disable Metrics/AbcSize
    def create_case_ready_for_less_than_cavc_affinty_days(judge)
      attorney = JudgeTeam.for_judge(judge).attorneys&.filter(&:attorney_in_vacols?)&.first ||
                 create(:user, :with_vacols_attorney_record)

      # go back to when we want the original appeal to have been decided
      Timecop.travel(4.years.ago)

      # create a decided appeal. all tasks are marked complete at the same time which won't affect distribution
      source = create(
        :appeal,
        :dispatched,
        :direct_review_docket,
        associated_judge: judge,
        associated_attorney: attorney,
        veteran: create_veteran
      )

      # go forward to when the remand is sent from CAVC. the source appeal's receipt_date will be the
      # remand appeal's receipt_date, this is just to have more realistic data
      Timecop.travel(1.year.from_now)

      # remand_appeal will have no tasks completed on it
      remand = create(:cavc_remand, source_appeal: source)

      # return system time back to now, then go to desired date where appeal will be ready for distribution
      # using [].max with 0 will ensure that if the lever is set to 0 we won't go into the future
      Timecop.return
      Timecop.travel([(CaseDistributionLever.cavc_affinity_days - 7), 0].max.days.ago)

      # complete the CAVC task and make the appeal ready to distribute
      remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      create(:appeal_affinity, appeal: remand.remand_appeal)

      Timecop.return
    end

    def create_case_ready_for_more_than_cavc_affinty_days(judge)
      attorney = JudgeTeam.for_judge(judge).attorneys&.filter(&:attorney_in_vacols?)&.first ||
                 create(:user, :with_vacols_attorney_record)

      # go back to when we want the original appeal to have been decided
      Timecop.travel(4.years.ago)

      # create a decided appeal. all tasks are marked complete at the same time which won't affect distribution
      source = create(
        :appeal,
        :dispatched,
        :direct_review_docket,
        associated_judge: judge,
        associated_attorney: attorney,
        veteran: create_veteran
      )

      # go forward to when the remand is sent from CAVC. the source appeal's receipt_date will be the
      # remand appeal's receipt_date, this is just to have more realistic data
      Timecop.travel(1.year.from_now)

      # remand_appeal will have no tasks completed on it
      remand = create(:cavc_remand, source_appeal: source)

      # return system time back to now, then go to desired date where appeal will be ready for distribution
      Timecop.return
      Timecop.travel((CaseDistributionLever.cavc_affinity_days + 7).days.ago)

      # complete the CAVC task and make the appeal ready to distribute
      remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      create(:appeal_affinity, appeal: remand.remand_appeal)

      Timecop.return
    end

    def create_case_ready_for_less_than_hearing_affinity_days(judge)
      # set system time and create the appeal
      Timecop.travel(4.years.ago)
      appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and remove 7 to make the case ready
      # for less than the hearing affinity days value
      Timecop.return
      Timecop.travel((91 + CaseDistributionLever.ama_hearing_case_affinity_days - 7).days.ago)
      create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
      create(:appeal_affinity, appeal: appeal)

      Timecop.return
    end

    def create_case_ready_for_less_than_aod_hearing_affinity_days(judge)
      # set system time and create the appeal
      Timecop.travel(4.years.ago)
      appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and remove 7 to make the case ready
      # for less than the hearing affinity days value
      Timecop.return
      Timecop.travel((91 + CaseDistributionLever.ama_hearing_case_aod_affinity_days - 7).days.ago)
      create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # created granted AOD motion to make this priority
      create(:advance_on_docket_motion, appeal: appeal, granted: true, person_id: appeal.claimant.person.id,
                                        reason: Constants.AOD_REASONS.financial_distress, user: User.system_user)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
      create(:appeal_affinity, appeal: appeal)

      Timecop.return
    end

    def create_case_ready_for_more_than_hearing_affinity_days(judge)
      # set system time and create the appeal
      Timecop.travel(4.years.ago)
      appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and add 7 more to make the case ready
      # for more than the hearing affinity days value
      Timecop.return
      Timecop.travel((91 + CaseDistributionLever.ama_hearing_case_affinity_days + 7).days.ago)
      create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
      create(:appeal_affinity, appeal: appeal)

      Timecop.return
    end

    def create_case_ready_for_more_than_aod_hearing_affinity_days(judge)
      # set system time and create the appeal
      Timecop.travel(4.years.ago)
      appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and add 7 more to make the case ready
      # for more than the hearing affinity days value
      Timecop.return
      Timecop.travel((91 + CaseDistributionLever.ama_hearing_case_aod_affinity_days + 7).days.ago)
      create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # created granted AOD motion to make this priority
      create(:advance_on_docket_motion, appeal: appeal, granted: true, person_id: appeal.claimant.person.id,
                                        reason: Constants.AOD_REASONS.financial_distress, user: User.system_user)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
      create(:appeal_affinity, appeal: appeal)

      Timecop.return
    end

    def create_ama_affinity_cases_set(judge, years_old)
      attorney = JudgeTeam.for_judge(judge).attorneys&.filter(&:attorney_in_vacols?)&.first ||
                 create(:user, :with_vacols_attorney_record)

      Timecop.travel(years_old.ago)

      direct_review_appeal = create(:appeal, :direct_review_docket, :ready_for_distribution, associated_judge: judge, veteran: create_veteran)
      evidence_submission_appeal = create(:appeal, :evidence_submission_docket, :ready_for_distribution, associated_judge: judge, veteran: create_veteran)
      hearing_appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)
      hearing_aod_appeal = create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and add 7 more to make the case ready
      # for more than the hearing affinity days value
      Timecop.return
      Timecop.travel(92.days.ago)
      create(:hearing, :held, appeal: hearing_appeal, judge: judge, adding_user: User.system_user)
      create(:hearing, :held, appeal: hearing_aod_appeal, judge: judge, adding_user: User.system_user)

      Timecop.travel(91.days.from_now)
      hearing_appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)
      hearing_aod_appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # created granted AOD motion to make this priority
      create(:advance_on_docket_motion, appeal: hearing_aod_appeal, granted: true, person_id: hearing_aod_appeal.claimant.person.id,
                                        reason: Constants.AOD_REASONS.financial_distress, user: User.system_user)

      # set the distribution task to assigned, if it was not already
      dist_task1 = hearing_appeal.tasks.where(type: DistributionTask.name).first
      dist_task2 = hearing_aod_appeal.tasks.where(type: DistributionTask.name).first
      dist_task1.assigned! unless dist_task1.assigned?
      dist_task2.assigned! unless dist_task2.assigned?

      Timecop.return
      Timecop.travel(years_old.ago)

      direct_review_cavc_appeal = create(
        :appeal,
        :dispatched,
        :direct_review_docket,
        associated_judge: judge,
        associated_attorney: attorney,
        veteran: create_veteran
      )
      evidence_submission_cavc_appeal = create(
        :appeal,
        :dispatched,
        :evidence_submission_docket,
        associated_judge: judge,
        associated_attorney: attorney,
        veteran: create_veteran
      )

      hearing_cavc_appeal = create(
        :appeal,
        :dispatched,
        :hearing_docket,
        associated_judge: judge,
        associated_attorney: attorney,
        veteran: create_veteran
      )

      Timecop.travel(1.year.from_now)

      # remand_appeal will have no tasks completed on it
      direct_review_cavc_remand = create(:cavc_remand, source_appeal: direct_review_cavc_appeal)
      evidence_submission_cavc_remand = create(:cavc_remand, source_appeal: evidence_submission_cavc_appeal)
      hearing_cavc_remand = create(:cavc_remand, source_appeal: hearing_cavc_appeal)

      # return system time back to now, then go to desired date where appeal will be ready for distribution
      Timecop.return

      # complete the CAVC task and make the appeal ready to distribute
      direct_review_cavc_remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      evidence_submission_cavc_remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      hearing_cavc_remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
    end

    def create_hearing_cavc_case_ready_at_n_days_ago(affinity_judge:, hearing_judge:, days_ago:)
      # Go back to when we want the original appeal to have been decided
      Timecop.travel(4.years.ago)

      # Create a decided appeal. all tasks are marked complete at the same time which won't affect distribution
      source = create(:appeal, :dispatched, :hearing_docket, associated_judge: affinity_judge)

      Timecop.travel(1.year.from_now)
      remand = create(:cavc_remand, source_appeal: source).remand_appeal
      Timecop.return

      # Travel to 9 mo. ago and then in smaller increments for a more "realistic" looking task tree
      Timecop.travel(9.months.ago)
      remand.tasks.where(type: SendCavcRemandProcessedLetterTask.name).map(&:completed!)
      create(:appeal_affinity, appeal: remand)

      Timecop.travel(1.month.from_now)
      # Call the creator class which will handle the task manipulation normally done by a distribution
      jat = JudgeAssignTaskCreator.new(appeal: remand, judge: affinity_judge, assigned_by_id: affinity_judge.id).call
      # Create and complete a ScheduleHearingColocatedTask, which will create a new DistributionTask and
      # HearingTask subtree to mimic how this would happen in a higher environment
      create(:colocated_task, :schedule_hearing, parent: jat, assigned_by: affinity_judge).completed!

      Timecop.travel(1.month.from_now)
      create(:hearing, :held, appeal: remand, judge: hearing_judge, adding_user: User.system_user)

      Timecop.travel(3.months.from_now)
      # Completes the remaining open HearingTask descendant tasks to make appeal ready to distribute
      remand.tasks.where(type: AssignHearingDispositionTask.name).flat_map(&:children).map(&:completed!)
      Timecop.return

      # When a DistributionTask goes to assigned it clears the affinity start date, so restore that at the right date
      Timecop.travel(days_ago.days.ago) { remand.appeal_affinity.update!(affinity_start_date: Time.zone.now) }

      # Return the remand appeal to let us track which appeals were created when run from a rails console
      remand
    end
    # rubocop:enable Metrics/AbcSize
  end
end
