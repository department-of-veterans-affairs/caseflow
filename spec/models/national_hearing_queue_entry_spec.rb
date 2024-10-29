# frozen_string_literal: true

require "rails_helper"

RSpec.describe NationalHearingQueueEntry, type: :model do
  self.use_transactional_tests = false

  # refresh in case anything was run in rails console previously
  before(:each) { NationalHearingQueueEntry.refresh }
  after(:each) { clean_up_after_threads }

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
      FactoryBot.create(:legacy_appeal,
                        :with_schedule_hearing_tasks,
                        :with_veteran,
                        vacols_case: case1)
    end

    let!(:legacy_appeal_completed) do
      FactoryBot.create(:legacy_appeal,
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

    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(:appeal_id, :appeal_type)
      ).to match_array [
        [ama_with_sched_task.id, "Appeal"],
        [legacy_with_sched_task.id, "LegacyAppeal"]
      ]
    end

    it "adds the Appeal info columns to the view in the proper format", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(
          :appeal_id, :appeal_type,
          :hearing_request_type, :receipt_date, :external_id,
          :appeal_stream, :docket_number
        )
      ).to match_array [
        [
          ama_with_sched_task.id,
          "Appeal",
          ama_with_sched_task.original_hearing_request_type,
          1.day.ago.strftime("%Y%m%d"),
          ama_with_sched_task.uuid,
          ama_with_sched_task.stream_type,
          ama_with_sched_task.stream_docket_number
        ],
        [
          legacy_with_sched_task.id,
          "LegacyAppeal",
          case1.bfhr,
          1.day.ago.strftime("%Y%m%d"),
          case1.bfkey,
          "Original",
          VACOLS::Folder.find_by_ticknum(case1.bfkey).tinum
        ]
      ]
    end
  end

  context "aod_indicator" do
    context "For AMA appeals" do
      let!(:appeal) do
        create(
          :appeal,
          :with_schedule_hearing_tasks,
          original_hearing_request_type: "central",
          aod_based_on_age: aod_based_on_age
        )
      end

      subject do
        NationalHearingQueueEntry.refresh

        NationalHearingQueueEntry.find_by(appeal: appeal).aod_indicator
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
      context "AOD motion" do
        context "Has been granted" do

        end

        context "Has not been granted" do

        end
      end

      context "Claimant is a Veteran" do
        context "Claimant is 75+ years old" do

        end

        context "Claimant is not 75 years old" do

        end
      end

      context "Claimant is not a Veteran" do
        context "Claimant is 75+ years old" do

        end

        context "Claimant is not 75 years old" do

        end
      end
    end
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
