# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do
  # refresh in case anything was run in rails console previously
  before(:each) { NationalHearingQueueEntry.refresh }

  context "aod_indicator" do
    subject do
      NationalHearingQueueEntry.refresh

      NationalHearingQueueEntry.find_by(appeal: appeal).aod_indicator
    end

    context "For AMA appeals" do
      let!(:appeal) do
        create(
          :appeal,
          :with_schedule_hearing_tasks,
          original_hearing_request_type: "central",
          aod_based_on_age: aod_based_on_age
        )
      end

      context "aod_based_on_age" do
        context "is true" do
          let(:aod_based_on_age) { true }

          it "aod_indicator is true" do
            is_expected.to be true
          end
        end

        context "is false" do
          let(:aod_based_on_age) { false }

          it "aod_indicator is false" do
            is_expected.to be false
          end
        end
      end

      context "Claimant is a Veteran" do
        # Pretend that the SetAppealAgeAodJob hasn't run yet
        let(:aod_based_on_age) { false }
        let(:claimant) { appeal.claimant }

        context "Claimant is 75+ years old" do
          let!(:person) do
            Person.find_by_participant_id(claimant.participant_id).tap do |person|
              person.update!(date_of_birth: 80.years.ago)
            end
          end

          it "aod_indicator is true" do
            expect(claimant.type).to eq "VeteranClaimant"

            is_expected.to be true
          end
        end

        context "Claimant is not 75+ years old" do
          let!(:person) do
            Person.find_by_participant_id(claimant.participant_id).tap do |person|
              person.update!(date_of_birth: 50.years.ago)
            end
          end

          it "aod_indicator is false" do
            expect(claimant.type).to eq "VeteranClaimant"

            is_expected.to be false
          end
        end
      end

      context "Claimant is a non-Veteran" do
        let(:aod_based_on_age) { false }
        let(:claimant) do
          appeal.claimant.tap do |claimant_to_update|
            claimant_to_update.update!(
              type: "DependentClaimant",
              participant_id: generate(:participant_id)
            )
          end
        end

        context "Claimant is 75+ years old" do
          let!(:person) do
            Person.find_or_create_by_participant_id(claimant.participant_id).tap do |person|
              person.update!(date_of_birth: 76.years.ago)
            end
          end

          it "aod_indicator is true" do
            expect(claimant.type).to_not eq "VeteranClaimant"
            expect(claimant.type).to eq "DependentClaimant"

            is_expected.to be true
          end
        end

        context "Claimant is not 75+ years old" do
          let!(:person) do
            Person.find_or_create_by_participant_id(claimant.participant_id).tap do |person|
              person.update!(date_of_birth: 30.years.ago)
            end
          end

          it "aod_indicator is false" do
            expect(claimant.type).to_not eq "VeteranClaimant"
            expect(claimant.type).to eq "DependentClaimant"

            is_expected.to be false
          end
        end
      end

      context "There are multiple claimants" do
        let(:aod_based_on_age) { false }
        let(:claimant_1) { appeal.claimant }
        let(:claimant_2) { create(:claimant, decision_review: appeal, type: "DependentClaimant") }

        context "Both are 75+ years old" do
          before do
            claimant_1.person.update!(date_of_birth: 78.years.ago)
            claimant_2.person.update!(date_of_birth: 77.years.ago)
          end

          it "aod_indicator is true" do
            expect(appeal.claimants.count).to eq 2

            is_expected.to eq true
          end
        end

        context "One is 75+ years old" do
          before do
            claimant_1.person.update!(date_of_birth: 78.years.ago)
            claimant_2.person.update!(date_of_birth: 50.years.ago)
          end

          it "aod_indicator is true" do
            expect(appeal.claimants.count).to eq 2

            is_expected.to eq true
          end
        end

        context "Neither are 75+ years old" do
          before do
            claimant_1.person.update!(date_of_birth: 20.years.ago)
            claimant_2.person.update!(date_of_birth: 45.years.ago)
          end

          it "aod_indicator is false" do
            expect(appeal.claimants.count).to eq 2

            is_expected.to eq false
          end
        end
      end

      context "Advance on docket motion" do
        let(:aod_based_on_age) { false }
        let!(:motion) do
          AdvanceOnDocketMotion.create!(
            appeal: appeal,
            person: appeal.claimant.person,
            granted: motion_granted
          )
        end

        context "Has been granted" do
          let(:motion_granted) { true }

          it "aod_indicator is true" do
            is_expected.to eq true
          end
        end

        context "Has been denied" do
          let(:motion_granted) { false }

          it "aod_indicator is false" do
            is_expected.to eq false
          end

          context "Claimant has turned 75 years old since AOD motion was denied" do
            before do
              Person.find_or_create_by_participant_id(appeal.claimant.participant_id).tap do |person|
                person.update!(date_of_birth: 85.years.ago)
              end
            end

            it "aod_indicator is true" do
              is_expected.to eq true
            end
          end
        end
      end
    end

    context "For legacy appeals" do
      after(:each) { clean_up_after_threads }

      let(:vacols_case) { create(:case, bfhr: "1", bfd19: 1.day.ago, bfac: "1") }
      let!(:appeal) do
        create(:legacy_appeal,
               :with_schedule_hearing_tasks,
               :with_veteran,
               vacols_case: vacols_case)
      end

      context "AOD motion" do
        context "Has been granted" do
          let!(:assign) do
            create(
              :diary,
              tsktknm: vacols_case.bfkey,
              tskactcd: "B"
            )
          end

          it "aod_indicator is true", bypass_cleaner: true do
            is_expected.to be true
          end
        end

        context "Has not been granted" do
          it "aod_indicator is false", bypass_cleaner: true do
            is_expected.to be false
          end
        end
      end

      context "Claimant is a Veteran" do
        let(:ssn) { Faker::IDNumber.ssn_valid.tr("-", "") }
        let(:claimant) do
          vacols_case.correspondent.tap do |corres|
            corres.update!(ssn: ssn, sspare2: nil)
          end
        end
        let!(:person) { Person.find_or_create_by_ssn(ssn) }

        context "Claimant is 75+ years old" do
          let(:claimant_dob) { 76.years.ago }

          it "aod_indicator is true", bypass_cleaner: true do
            claimant.update!(sdob: claimant_dob)

            is_expected.to be true
          end
        end

        context "Claimant is not 75 years old" do
          let(:claimant_dob) { 18.years.ago }

          it "aod_indicator is false", bypass_cleaner: true do
            claimant.update!(sdob: claimant_dob)

            is_expected.to be false
          end
        end
      end

      context "Claimant is not a Veteran" do
        let(:ssn) { Faker::IDNumber.ssn_valid.tr("-", "") }
        let(:claimant) do
          vacols_case.correspondent.tap do |corres|
            corres.update!(ssn: ssn, sspare2: "Test")
          end
        end
        let!(:person) do
          create(:person, ssn: ssn, date_of_birth: claimant_dob)
        end

        before { claimant.save! }

        context "Claimant is 75+ years old" do
          let(:claimant_dob) { 80.years.ago }

          it "aod_indicator is true", bypass_cleaner: true do
            is_expected.to be true
          end
        end

        context "Claimant is not 75 years old" do
          let(:claimant_dob) { 25.years.ago }

          it "aod_indicator is false", bypass_cleaner: true do
            is_expected.to be false
          end
        end
      end
    end
  end

  context "when appeals have been staged" do
    let!(:ama_with_sched_task) do
      create(
        :appeal,
        :with_schedule_hearing_tasks,
        original_hearing_request_type: "central"
      )
    end

    let!(:ama_with_completed_status) do
      create(:appeal, :with_schedule_hearing_tasks).tap do |appeal|
        ScheduleHearingTask.find_by(appeal: appeal).completed!
      end
    end

    let!(:case1) { create(:case, bfhr: "1", bfd19: 1.day.ago, bfac: "1") }
    let!(:case2) { create(:case, bfhr: "2", bfd19: 2.days.ago, bfac: "5") }
    let!(:case3) { create(:case, bfhr: "3", bfd19: 3.days.ago, bfac: "9") }

    let!(:legacy_with_sched_task) do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: case1)
    end

    let!(:legacy_appeal_completed) do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: case3).tap do |legacy_appeal|
        ScheduleHearingTask.find_by(appeal: legacy_appeal).completed!
      end
    end

    let!(:appeal_normal) { create(:appeal) }

    let!(:legacy_appeal_normal) do
      create(:legacy_appeal,
             :with_root_task,
             :with_veteran,
             vacols_case: case2)
    end

    let(:ama_hearing_task) { ama_with_sched_task.tasks.find_by(type: "ScheduleHearingTask") }
    let(:legacy_hearing_task) { legacy_with_sched_task.tasks.find_by(type: "ScheduleHearingTask") }

    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(:appeal_id, :appeal_type)
      ).to match_array [
        [ama_with_sched_task.id, "Appeal"],
        [legacy_with_sched_task.id, "LegacyAppeal"]
      ]

      clean_up_after_threads
    end

    it "adds the Appeal info columns to the view in the proper format", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      # rubocop:disable Rails/TimeZone
      ama_hearing_task.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now)
      legacy_hearing_task.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now)
      # rubocop:enable Rails/TimeZone

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(
          :appeal_id, :appeal_type,
          :hearing_request_type, :receipt_date, :external_id,
          :appeal_stream, :docket_number, :aod_indicator,
          :task_id, :schedulable, :assigned_to_id,
          :assigned_by_id, :days_on_hold, :days_waiting,
          :task_status
        )
      ).to match_array [
        [
          ama_with_sched_task.id,
          "Appeal",
          ama_with_sched_task.original_hearing_request_type,
          1.day.ago.strftime("%Y%m%d"),
          ama_with_sched_task.uuid,
          ama_with_sched_task.stream_type,
          ama_with_sched_task.stream_docket_number,
          false,
          ama_with_sched_task.tasks.find_by_type("ScheduleHearingTask").id,
          false,
          ama_hearing_task.assigned_to_id,
          ama_hearing_task.assigned_by_id,
          ((Time.zone.now - ama_hearing_task.placed_on_hold_at) / 60 / 60 / 24).floor,
          ((ama_hearing_task.closed_at - ama_hearing_task.created_at) / 60 / 60 / 24).floor,
          ama_hearing_task.status
        ],
        [
          legacy_with_sched_task.id,
          "LegacyAppeal",
          case1.bfhr,
          1.day.ago.strftime("%Y%m%d"),
          case1.bfkey,
          "Original",
          VACOLS::Folder.find_by_ticknum(case1.bfkey).tinum,
          false,
          legacy_with_sched_task.tasks.find_by_type("ScheduleHearingTask").id,
          true,
          legacy_hearing_task.assigned_to_id,
          legacy_hearing_task.assigned_by_id,
          ((Time.zone.now - legacy_hearing_task.placed_on_hold_at) / 60 / 60 / 24).floor,
          ((legacy_hearing_task.closed_at - legacy_hearing_task.created_at) / 60 / 60 / 24).floor,
          legacy_hearing_task.status
        ]
      ]

      clean_up_after_threads
    end
  end

  context "schedulable" do
    after(:each) { clean_up_after_threads }

    let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    let(:vacols_case) { create(:case, bfhr: "1", bfd19: 1.day.ago, bfac: "1") }
    let!(:legacy_appeal) do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: vacols_case)
    end

    it "is schedulable when its a legacy appeal", bypass_cleaner: true do
      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: legacy_appeal
      ).schedulable
      expect(schedulable).to eq(true)
    end

    it "is schedulable when AMA appeal is court remand" do
      appeal.update!(stream_type: "court_remand")
      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: appeal
      ).schedulable

      expect(schedulable).to eq(true)
    end

    it "is schedulable when AMA appeal is AOD" do
      appeal.update!(aod_based_on_age: true)
      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: appeal
      ).schedulable

      expect(schedulable).to eq(true)
    end

    it "is schedulable when AMA appeal receipt date is before 2020" do
      appeal.update!(receipt_date: Date.new(2019, 12, 31))

      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: appeal
      ).schedulable

      expect(schedulable).to eq(true)
    end

    it "is not schedulable when an AMA appeal doesn't meet any of the necessary conditions" do
      appeal.update!(
        receipt_date: Date.new(2020, 1, 1),
        aod_based_on_age: false,
        stream_type: "original"
      )

      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: appeal
      ).schedulable

      expect(schedulable).to eq(false)
    end
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
