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
      # substring for single letter suffix
      let(:ssn) { Veteran.find_by(file_number: vacols_case.bfcorlid[0..vacols_case.bfcorlid.length - 2]).ssn }

      before { VACOLS::Correspondent.find(vacols_case.bfcorkey).update!(ssn: ssn) }

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

    let!(:ama_with_sched_task2) do
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
    let!(:case4) { create(:case, bfhr: "4", bfd19: 1.day.ago, bfac: "1") }

    let!(:legacy_request_issues) do
      [
        create(:case_issue, isskey: case4.bfkey, issmst: "Y", isspact: "N"),
        create(:case_issue, isskey: case4.bfkey, issmst: "N", isspact: "Y")
      ]
    end

    let!(:legacy_with_sched_task) do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: case1)
    end

    let!(:legacy_with_sched_task2) do
      case4.case_issues = legacy_request_issues
      case4.save!
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: case4)
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

    let(:ssn1) { Veteran.find_by(file_number: case1.bfcorlid[0..case1.bfcorlid.length - 2]).ssn }
    let(:ssn2) { Veteran.find_by(file_number: case2.bfcorlid[0..case2.bfcorlid.length - 2]).ssn }
    let(:ssn3) { Veteran.find_by(file_number: case3.bfcorlid[0..case3.bfcorlid.length - 2]).ssn }
    let(:ssn4) { Veteran.find_by(file_number: case4.bfcorlid[0..case4.bfcorlid.length - 2]).ssn }

    let(:request_issues) do
      [
        create(:request_issue, nonrating_issue_category: "Category C", mst_status: false, pact_status: false),
        create(:request_issue, nonrating_issue_category: "Category B", mst_status: false, pact_status: false),
        create(:request_issue, nonrating_issue_category: "Category C", mst_status: false, pact_status: false),
        create(:request_issue, nonrating_issue_category: "Category D", mst_status: false, pact_status: false)
      ]
    end

    let(:request_issues_mst_pact) do
      [
        create(:request_issue, nonrating_issue_category: "Category C", mst_status: true, pact_status: false),
        create(:request_issue, nonrating_issue_category: "Category B", mst_status: false, pact_status: true),
        create(:request_issue, nonrating_issue_category: "Category C", mst_status: false, pact_status: false),
        create(:request_issue, nonrating_issue_category: "Category D", mst_status: false, pact_status: false)
      ]
    end

    before do
      # legacy appeal update
      cases = [case1, case2, case3, case4]
      ssns = [ssn1, ssn2, ssn3, ssn4]
      veteran_deceased = [true, false, false, false]

      cases.each_with_index do |c, index|
        VACOLS::Correspondent.find(c.bfcorkey).update!(ssn: ssns[index],
                                                       sfnod: veteran_deceased[index] ? Time.zone.now : nil)

        file_number = c.bfcorlid[0..c.bfcorlid.length - 2]

        veteran = Veteran.find_by(file_number: file_number)
        veteran.update!(state_of_residence: "va")
        veteran.update!(country_of_residence: "usa")
      end

      # ama state and country update
      Veteran.find_by(file_number:
        ama_with_sched_task.veteran_file_number).update!(state_of_residence: "va",
                                                         country_of_residence: "usa",
                                                         date_of_death: Time.zone.now,
                                                         date_of_death_reported_at: Time.zone.now)
      Veteran.find_by(file_number:
        ama_with_sched_task2.veteran_file_number).update!(state_of_residence: "va",
                                                          country_of_residence: "usa")

      # caching ama appeal
      ama_with_sched_task.request_issues = request_issues
      ama_with_sched_task.save
      ama_with_sched_task2.request_issues = request_issues_mst_pact
      ama_with_sched_task2.save
      CachedAppealService.new.cache_ama_appeals([ama_with_sched_task])
      CachedAppealService.new.cache_ama_appeals([ama_with_sched_task2])
      ActiveRecord::Base.connection.execute(
        "UPDATE cached_appeal_attributes
         SET suggested_hearing_location = 'Oakland, CA (RO)'
         WHERE appeal_id = #{ama_with_sched_task.id} AND appeal_type = 'Appeal'"
      )
      ActiveRecord::Base.connection.execute(
        "UPDATE cached_appeal_attributes
         SET suggested_hearing_location = 'Oakland, CA (RO)'
         WHERE appeal_id = #{ama_with_sched_task2.id} AND appeal_type = 'Appeal'"
      )

      # caching legacy appeal
      CachedAppealService.new.cache_legacy_appeal_postgres_data([legacy_with_sched_task])
      CachedAppealService.new.cache_legacy_appeal_postgres_data([legacy_with_sched_task2])
      CachedAppealService.new.cache_legacy_appeal_vacols_data([case1.bfkey])
      CachedAppealService.new.cache_legacy_appeal_vacols_data([case2.bfkey])
      CachedAppealService.new.cache_legacy_appeal_vacols_data([case3.bfkey])
      CachedAppealService.new.cache_legacy_appeal_vacols_data([case4.bfkey])

      ActiveRecord::Base.connection.execute(
        "UPDATE cached_appeal_attributes
         SET suggested_hearing_location = 'Oakland, CA (RO)'
         WHERE appeal_id = #{legacy_with_sched_task.id} AND appeal_type = 'LegacyAppeal'"
      )
      ActiveRecord::Base.connection.execute(
        "UPDATE cached_appeal_attributes
         SET suggested_hearing_location = 'Oakland, CA (RO)'
         WHERE appeal_id = #{legacy_with_sched_task2.id} AND appeal_type = 'LegacyAppeal'"
      )
    end

    let!(:ama_hearing_task) { ama_with_sched_task.tasks.find_by(type: "ScheduleHearingTask") }
    let!(:ama_hearing_task2) { ama_with_sched_task2.tasks.find_by(type: "ScheduleHearingTask") }
    let!(:legacy_hearing_task) { legacy_with_sched_task.tasks.find_by(type: "ScheduleHearingTask") }
    let!(:legacy_hearing_task2) { legacy_with_sched_task2.tasks.find_by(type: "ScheduleHearingTask") }

    it "refreshes the view and returns the proper appeals", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(:appeal_id, :appeal_type)
      ).to match_array [
        [ama_with_sched_task.id, "Appeal"],
        [ama_with_sched_task2.id, "Appeal"],
        [legacy_with_sched_task.id, "LegacyAppeal"],
        [legacy_with_sched_task2.id, "LegacyAppeal"]
      ]

      clean_up_after_threads
    end

    it "adds the Appeal info columns to the view in the proper format", bypass_cleaner: true do
      expect(NationalHearingQueueEntry.count).to eq 0

      # rubocop:disable Rails/TimeZone
      ama_hearing_task.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now, status: "on_hold")
      legacy_hearing_task.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now, status: "on_hold")
      ama_hearing_task2.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now, status: "on_hold")
      legacy_hearing_task2.update!(placed_on_hold_at: 7.days.ago, closed_at: Time.now, status: "on_hold")
      # rubocop:enable Rails/TimeZone

      NationalHearingQueueEntry.refresh

      expect(
        NationalHearingQueueEntry.pluck(
          :appeal_id, :appeal_type,
          :hearing_request_type, :receipt_date, :external_id,
          :appeal_stream, :docket_number, :aod_indicator,
          :task_id, :schedulable, :assigned_to_id,
          :assigned_by_id, :days_on_hold, :days_waiting,
          :task_status, :state_of_residence, :country_of_residence,
          :suggested_hearing_location, :mst_indicator, :pact_indicator,
          :veteran_deceased_indicator
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
          ama_hearing_task.status,
          "va",
          "usa",
          "Oakland, CA (RO)",
          false,
          false,
          true
        ],
        [
          ama_with_sched_task2.id,
          "Appeal",
          ama_with_sched_task2.original_hearing_request_type,
          1.day.ago.strftime("%Y%m%d"),
          ama_with_sched_task2.uuid,
          ama_with_sched_task2.stream_type,
          ama_with_sched_task2.stream_docket_number,
          false,
          ama_with_sched_task2.tasks.find_by_type("ScheduleHearingTask").id,
          false,
          ama_hearing_task2.assigned_to_id,
          ama_hearing_task2.assigned_by_id,
          ((Time.zone.now - ama_hearing_task2.placed_on_hold_at) / 60 / 60 / 24).floor,
          ((ama_hearing_task2.closed_at - ama_hearing_task2.created_at) / 60 / 60 / 24).floor,
          ama_hearing_task2.status,
          "va",
          "usa",
          "Oakland, CA (RO)",
          true,
          true,
          false
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
          legacy_hearing_task.status,
          "va",
          "usa",
          "Oakland, CA (RO)",
          false,
          false,
          true
        ],
        [
          legacy_with_sched_task2.id,
          "LegacyAppeal",
          case4.bfhr,
          1.day.ago.strftime("%Y%m%d"),
          case4.bfkey,
          "Original",
          VACOLS::Folder.find_by_ticknum(case4.bfkey).tinum,
          false,
          legacy_with_sched_task2.tasks.find_by_type("ScheduleHearingTask").id,
          true,
          legacy_hearing_task2.assigned_to_id,
          legacy_hearing_task2.assigned_by_id,
          ((Time.zone.now - legacy_hearing_task2.placed_on_hold_at) / 60 / 60 / 24).floor,
          ((legacy_hearing_task2.closed_at - legacy_hearing_task2.created_at) / 60 / 60 / 24).floor,
          legacy_hearing_task2.status,
          "va",
          "usa",
          "Oakland, CA (RO)",
          true,
          true,
          false
        ]
      ]

      clean_up_after_threads
    end
  end

  context "schedulable" do
    after(:each) { clean_up_after_threads }

    let!(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    let!(:vacols_case) { create(:case, bfhr: "1", bfd19: 1.day.ago, bfac: "1") }
    let!(:legacy_appeal) do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: vacols_case)
    end

    let(:ssn) { Veteran.find_by(file_number: vacols_case.bfcorlid[0..vacols_case.bfcorlid.length - 2]).ssn }

    before { VACOLS::Correspondent.find(vacols_case.bfcorkey).update!(ssn: ssn) }

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

    it "is schedulable when AMA appeal receipt date is before 2020 and no " \
     "user-specified cutoff dates exist" do
      appeal.update!(receipt_date: Date.new(2019, 12, 31))

      NationalHearingQueueEntry.refresh
      schedulable = NationalHearingQueueEntry.find_by(
        appeal: appeal
      ).schedulable

      expect(schedulable).to eq(true)
    end

    it "is schedulable when AMA appeal receipt date is before the cutoff date" do
      appeal.update!(receipt_date: Time.zone.today)
      NationalHearingQueueEntry.refresh
      entry = NationalHearingQueueEntry.find_by(
        appeal: appeal
      )

      expect(entry.schedulable).to eq(false)
      SchedulableCutoffDate.create!(created_by_id: entry.assigned_to_id, cutoff_date: Time.zone.today + 10.days)
      NationalHearingQueueEntry.refresh
      entry = NationalHearingQueueEntry.find_by(
        appeal: appeal
      )
      expect(entry.schedulable).to eq(true)
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

  context "priority_queue_number" do
    after(:each) { clean_up_after_threads }

    subject { NationalHearingQueueEntry.refresh }

    context "whenever the queue is blank" do
      it "No errors are thrown whenever the queue is refreshed" do
        expect { subject }.to_not raise_error
      end
    end

    context "Whenever there are a variety of items in the queue" do
      let!(:legacy_cavc_aod_appeal_one) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true)
      end

      let!(:legacy_cavc_aod_appeal_two) do
        stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: true)
      end

      let!(:legacy_cavc_aod_appeal_three) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true)
      end

      let!(:ama_cavc_aod_appeal_one) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true)
      end

      let!(:ama_cavc_aod_appeal_two) do
        stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true)
      end

      let!(:ama_cavc_aod_appeal_three) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true)
      end

      let!(:legacy_cavc_appeal_one) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true)
      end

      let!(:legacy_cavc_appeal_two) do
        stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: true)
      end

      let!(:legacy_cavc_appeal_three) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true)
      end

      let!(:ama_cavc_appeal_one) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true)
      end

      let!(:ama_cavc_appeal_two) do
        stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true)
      end

      let!(:ama_cavc_appeal_three) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true)
      end

      let!(:ama_aod_appeal_one) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false)
      end

      let!(:ama_aod_appeal_two) do
        stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false)
      end

      let!(:ama_aod_appeal_three) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false)
      end

      let!(:legacy_aod_appeal_one) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false)
      end

      let!(:legacy_aod_appeal_two) do
        stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: false)
      end

      let!(:legacy_aod_appeal_three) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false)
      end

      let!(:ama_appeal_one) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false)
      end

      let!(:ama_appeal_two) do
        stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false)
      end

      let!(:ama_appeal_three) do
        stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false)
      end

      let!(:legacy_appeal_one) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false)
      end

      let!(:legacy_appeal_two) do
        stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: false)
      end

      let!(:legacy_appeal_three) do
        stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false)
      end

      it "The appeals are ordered correctly based upon their attributes", bypass_cleaner: true do
        subject

        ##############
        #  CAVC + AOD
        ##############

        # Two week old CAVC + AOD Legacy Appeals
        expect(legacy_cavc_aod_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 1
        expect(legacy_cavc_aod_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 2

        # Two week old CAVC + AOD AMA Appeals
        expect(ama_cavc_aod_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 3
        expect(ama_cavc_aod_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 4

        # One day old CAVC + AOD Legacy Appeal
        expect(legacy_cavc_aod_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 5

        # One day old CAVC + AOD AMA Appeal
        expect(ama_cavc_aod_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 6

        #############################
        #  CAVC Remands - Non-AOD
        #############################

        # Two week old CAVC Remanded Legacy Appeals
        expect(legacy_cavc_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 7
        expect(legacy_cavc_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 8

        # Two week old CAVC Remanded AMA Appeals
        expect(ama_cavc_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 9
        expect(ama_cavc_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 10

        # One day old CAVC Remanded Legacy Appeal
        expect(legacy_cavc_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 11

        # One day old CAVC Remanded AMA Appeal
        expect(ama_cavc_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 12

        ###################################
        #  AOD - Original Docket Streams
        ###################################

        # Two week old AOD Legacy Appeals
        expect(legacy_aod_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 13
        expect(legacy_aod_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 14

        # Two week old AOD AMA Appeals
        expect(ama_aod_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 15
        expect(ama_aod_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 16

        # One day old AOD Legacy Appeal
        expect(legacy_aod_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 17

        # One day old AOD AMA Appeal
        expect(ama_aod_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 18

        ###################################
        #  Original Docket Streams - Non-AOD
        ###################################

        # Two week old original Legacy Appeals
        expect(legacy_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 19
        expect(legacy_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 20

        # Two week old original AMA Appeals
        expect(ama_appeal_one.national_hearing_queue_entry.priority_queue_number).to eq 21
        expect(ama_appeal_three.national_hearing_queue_entry.priority_queue_number).to eq 22

        # One day old original Legacy Appeal
        expect(legacy_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 23

        # One day old original AMA Appeal
        expect(ama_appeal_two.national_hearing_queue_entry.priority_queue_number).to eq 24
      end
    end

    context "CAVC + AOD Appeals" do
      context "Whenever there are two legacy appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }
          let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }
          let!(:created_second) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there are two AMA appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }
          let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }
          let!(:created_second) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there is a legacy appeal and an AMA appeal" do
        context "The appeals were received on different dates" do
          context "The legacy appeal was received first" do
            let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }
            let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end

          context "The AMA appeal was received first" do
            let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }
            let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: true) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end
        end

        context "The appeals were received on the same date" do
          let!(:legacy_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }
          let!(:ama_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }

          it "the legacy appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              legacy_appeal.national_hearing_queue_entry.priority_queue_number <
                ama_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Priority in relation to other types of appeals" do
        let!(:cavc_aod_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }

        context "versus a CAVC only appeal" do
          let!(:cavc_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                cavc_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus an AOD only appeal" do
          let!(:aod_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                aod_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus a non CAVC or AOD appeal" do
          let!(:regular_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end
    end

    context "CAVC Only Appeals" do
      context "Whenever there are two legacy appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }
          let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }
          let!(:created_second) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there are two AMA appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }
          let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }
          let!(:created_second) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there is a legacy appeal and an AMA appeal" do
        context "The appeals were received on different dates" do
          context "The legacy appeal was received first" do
            let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }
            let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end

          context "The AMA appeal was received first" do
            let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }
            let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: true) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end
        end

        context "The appeals were received on the same date" do
          let!(:legacy_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }
          let!(:ama_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }

          it "the legacy appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              legacy_appeal.national_hearing_queue_entry.priority_queue_number <
                ama_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Priority in relation to other types of appeals" do
        let!(:cavc_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }

        context "versus a CAVC + AOD appeal" do
          let!(:cavc_aod_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                cavc_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus an AOD only appeal" do
          let!(:aod_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }

          it "the CAVC appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_only_appeal.national_hearing_queue_entry.priority_queue_number <
                aod_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus a non CAVC or AOD appeal" do
          let!(:regular_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }

          it "the CAVC appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_only_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end
    end

    context "AOD Only Appeals" do
      context "Whenever there are two legacy appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }
          let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }
          let!(:created_second) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there are two AMA appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }
          let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }
          let!(:created_second) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there is a legacy appeal and an AMA appeal" do
        context "The appeals were received on different dates" do
          context "The legacy appeal was received first" do
            let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }
            let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end

          context "The AMA appeal was received first" do
            let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }
            let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: true, cavc: false) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end
        end

        context "The appeals were received on the same date" do
          let!(:legacy_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }
          let!(:ama_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }

          it "the legacy appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              legacy_appeal.national_hearing_queue_entry.priority_queue_number <
                ama_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Priority in relation to other types of appeals" do
        let!(:aod_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }

        context "versus a CAVC + AOD appeal" do
          let!(:cavc_aod_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                aod_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus a CAVC only appeal" do
          let!(:cavc_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }

          it "the CAVC appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_only_appeal.national_hearing_queue_entry.priority_queue_number <
                aod_only_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus a non CAVC or AOD appeal" do
          let!(:regular_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }

          it "the AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              aod_only_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end
    end

    context "Neither CAVC or AOD Appeals" do
      context "Whenever there are two legacy appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }
          let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }
          let!(:created_second) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there are two AMA appeals" do
        context "The appeals were received on different dates" do
          let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }
          let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

          it "the older appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              older_appeal.national_hearing_queue_entry.priority_queue_number <
                newer_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "The appeals were received on the same date" do
          let!(:created_first) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }
          let!(:created_second) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

          it "the appeal received earlier in the day is prioritized more highly", bypass_cleaner: true do
            subject

            expect(
              created_first.national_hearing_queue_entry.priority_queue_number <
                created_second.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Whenever there is a legacy appeal and an AMA appeal" do
        context "The appeals were received on different dates" do
          context "The legacy appeal was received first" do
            let!(:newer_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }
            let!(:older_appeal) { stage_legacy_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end

          context "The AMA appeal was received first" do
            let!(:newer_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }
            let!(:older_appeal) { stage_ama_appeal(receipt_date: 2.weeks.ago, aod: false, cavc: false) }

            it "the older appeal is prioritized higher", bypass_cleaner: true do
              subject

              expect(
                older_appeal.national_hearing_queue_entry.priority_queue_number <
                  newer_appeal.national_hearing_queue_entry.priority_queue_number
              ).to eq true
            end
          end
        end

        context "The appeals were received on the same date" do
          let!(:legacy_appeal) { stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }
          let!(:ama_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }

          it "the legacy appeal is prioritized higher", bypass_cleaner: true do
            subject

            expect(
              legacy_appeal.national_hearing_queue_entry.priority_queue_number <
                ama_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end

      context "Priority in relation to other types of appeals" do
        let!(:regular_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false) }

        context "versus a CAVC + AOD appeal" do
          let!(:cavc_aod_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: true) }

          it "the CAVC + AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_aod_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus a CAVC only appeal" do
          let!(:cavc_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: true) }

          it "the CAVC appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              cavc_only_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end

        context "versus an AOD only appeal" do
          let!(:aod_only_appeal) { stage_ama_appeal(receipt_date: 1.day.ago, aod: true, cavc: false) }

          it "the AOD appeal has the higher priority", bypass_cleaner: true do
            subject

            expect(
              aod_only_appeal.national_hearing_queue_entry.priority_queue_number <
                regular_appeal.national_hearing_queue_entry.priority_queue_number
            ).to eq true
          end
        end
      end
    end
  end

  def stage_legacy_appeal(receipt_date: 1.day.ago, aod: false, cavc: false)
    vacols_case = create(:case, bfhr: "1", bfd19: receipt_date, bfac: cavc ? "7" : "1")

    create(:diary, tsktknm: vacols_case.bfkey, tskactcd: "B") if aod

    create(:legacy_appeal,
           :with_schedule_hearing_tasks,
           :with_veteran,
           vacols_case: vacols_case).tap do |appeal|
      appeal.case_record.correspondent.update!(ssn: appeal.veteran.ssn)
    end
  end

  def stage_ama_appeal(receipt_date: 1.day.ago, aod: false, cavc: false)
    create(
      :appeal,
      :with_schedule_hearing_tasks,
      stream_type: cavc ? "court_remand" : "original",
      receipt_date: receipt_date,
      aod_based_on_age: aod
    )
  end

  def clean_up_after_threads
    DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
  end
end
