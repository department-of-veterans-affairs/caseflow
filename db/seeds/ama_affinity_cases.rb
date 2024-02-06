# frozen_string_literal: true

# This seed creates ~100 appeals which have an affinity to a judge based on levers in DISTRIBUTION.json,
# and ~100 appeals which are similar but fall just outside of the affinity day levers and will be distributed
# to any judge. Used primarily in testing APPEALS-36998 and other ACD feature work
module Seeds
  class AmaAffinityCases < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_file_number_and_participant_id
    end

    def seed!
      create_cavc_affinity_cases
      create_hearing_affinity_cases
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
      create(
        :veteran,
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      )
    end

    def create_cavc_affinity_cases
      judges_with_attorneys.each do |judge|
        3.times do
          create_case_ready_for_less_than_cavc_affinty_days(judge)
          create_case_ready_for_more_than_cavc_affinty_days(judge)
        end
      end
    end

    def create_hearing_affinity_cases
      judges_with_attorneys.each do |judge|
        3.times do
          create_case_ready_for_less_than_hearing_affinity_days(judge)
          create_case_ready_for_more_than_hearing_affinity_days(judge)
        end
      end
    end

    def judges_with_attorneys
      # use judges with attorneys to minimize how many cases are distributed when testing because the
      # alternative_batch_size is higher than the batch_size for most judge teams
      @judges_with_attorneys ||= JudgeTeam.all.reject { |jt| jt.attorneys.empty? }.map(&:judge).compact
    end

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
      Timecop.travel([(Constants.DISTRIBUTION.cavc_affinity_days - 7), 0].max.days.ago)

      # complete the CAVC task and make the appeal ready to distribute
      remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!

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
      Timecop.travel((Constants.DISTRIBUTION.cavc_affinity_days + 7).days.ago)

      # complete the CAVC task and make the appeal ready to distribute
      remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!

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
      Timecop.travel((91 + Constants.DISTRIBUTION.hearing_case_affinity_days - 7).days.ago)
      create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
    end

    def create_case_ready_for_more_than_hearing_affinity_days(judge)
      # set system time and create the appeal
      Timecop.travel(4.years.ago)
      appeal = FactoryBot.create(:appeal, :hearing_docket, :with_post_intake_tasks, veteran: create_veteran)

      # travel to when the hearing was held, then create the held hearing and post-hearing tasks:
      # add 91 days for the amount of time the post-hearing tasks are open and add 7 more to make the case ready
      # for more than the hearing affinity days value
      Timecop.return
      Timecop.travel((91 + Constants.DISTRIBUTION.hearing_case_affinity_days + 7).days.ago)
      FactoryBot.create(:hearing, :held, appeal: appeal, judge: judge, adding_user: User.system_user)

      # travel to when the tasks will auto-complete and complete them
      Timecop.travel(91.days.from_now)
      appeal.tasks.where(type: AssignHearingDispositionTask.name).first.children.map(&:completed!)

      # set the distribution task to assigned, if it was not already
      dist_task = appeal.tasks.where(type: DistributionTask.name).first
      dist_task.assigned! unless dist_task.assigned?
    end
  end
end
