# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::TranscriptionFilesController, type: :controller do
  describe "GET download_transcription_file" do
    let!(:user) { User.authenticate!(roles: ["Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched"]) }

    let!(:hearing) { create(:hearing, :with_transcription_files) }
    let(:transcription_file) { hearing.transcription_files.first }
    let(:options) { { format: :vtt, file_id: transcription_file.id } }

    it "opens file" do
      allow(File).to receive(:open).and_return("test data")
      get :download_transcription_file, params: options
      expect(response.status).to eq(204)
    end

    context "when not a hearings user" do
      let(:vso_user) { create(:user, :vso_role) }
      before do
        User.unauthenticate!
        User.authenticate!(user: vso_user)
      end
      it "redirects to unauthorized" do
        get :download_transcription_file, params: options
        expect(response).to redirect_to("/unauthorized")
      end
    end
  end

  describe "GET transcription_file_tasks" do
    let!(:user) { User.authenticate!(roles: ["Transcriptions"]) }
    before { TranscriptionTeam.singleton.add_user(user) }

    let(:file_status_uploaded) { Constants.TRANSCRIPTION_FILE_STATUSES.upload.success }
    let(:file_status_retrieval) { Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.success }

    let(:hearing_day_1) { create(:hearing_day, scheduled_for: "2014-01-19") }
    let(:hearing_day_2) { create(:hearing_day, scheduled_for: "2020-05-14") }
    let(:hearing_day_3) { create(:hearing_day, scheduled_for: "2007-06-30") }
    let(:hearing_day_4) { create(:hearing_day, scheduled_for: "2024-01-17") }

    let!(:appeal_1) { create(:appeal, stream_type: "original", aod_based_on_age: true) }
    let!(:appeal_2) { create(:appeal, stream_type: "original") }
    let!(:appeal_3) { create(:appeal, stream_type: "original") }

    let!(:hearing_1) { create(:hearing, appeal: appeal_1, hearing_day: hearing_day_1) }
    let!(:hearing_2) { create(:hearing, appeal: appeal_2, hearing_day: hearing_day_2) }
    let!(:hearing_3) { create(:hearing, appeal: appeal_3, hearing_day: hearing_day_3) }

    let!(:legacy_hearing_1) { create(:legacy_hearing, hearing_day: hearing_day_4) }

    let!(:advance_on_docket_motion_1) { create(:advance_on_docket_motion, granted: true, appeal: hearing_2.appeal) }

    let!(:transcription_package_1) { create(:transcription_package, task_number: "BVA2025001") }

    let!(:transcription_1) { create(:transcription, task_number: "BVA2025001") }

    let!(:transcription_file_1) { create(:transcription_file, hearing: hearing_1, file_status: file_status_uploaded) }
    let!(:transcription_file_2) { create(:transcription_file, hearing: hearing_2, file_status: file_status_uploaded) }
    let!(:transcription_file_3) do
      create(
        :transcription_file,
        hearing: legacy_hearing_1,
        file_status: file_status_uploaded,
        docket_number: "search-test"
      )
    end

    let!(:transcription_file_4) do
      create(
        :transcription_file,
        hearing: hearing_3,
        file_status: file_status_retrieval,
        transcription_id: transcription_1.id,
        date_returned_box: Time.zone.now + 16.days,
        date_upload_box: Time.zone.now + 12.days
      )
    end

    let(:transcription_response_1) do
      {
        id: transcription_file_1.id,
        externalAppealId: appeal_1.uuid,
        docketNumber: transcription_file_1.docket_number,
        caseDetails: "#{appeal_1.appellant_or_veteran_name} (#{appeal_1.veteran_file_number})",
        isAdvancedOnDocket: true,
        caseType: "Original",
        hearingDate: hearing_1.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_1.hearing_type,
        fileStatus: transcription_file_1.file_status,
        fileName: transcription_file_1.file_name
      }
    end

    let(:transcription_response_2) do
      {
        id: transcription_file_2.id,
        externalAppealId: appeal_2.uuid,
        docketNumber: transcription_file_2.docket_number,
        caseDetails: "#{appeal_2.appellant_or_veteran_name} (#{appeal_2.veteran_file_number})",
        isAdvancedOnDocket: true,
        caseType: "Original",
        hearingDate: hearing_2.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_2.hearing_type,
        fileStatus: transcription_file_2.file_status,
        fileName: transcription_file_2.file_name
      }
    end

    let(:transcription_response_3) do
      {
        id: transcription_file_3.id,
        externalAppealId: transcription_file_3.hearing.appeal.vacols_id,
        docketNumber: transcription_file_3.docket_number,
        caseDetails: "#{transcription_file_3.hearing.appeal.appellant_or_veteran_name} " \
          "(#{transcription_file_3.hearing.appeal.veteran_file_number})",
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: legacy_hearing_1.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_3.hearing_type,
        fileStatus: transcription_file_3.file_status,
        fileName: transcription_file_3.file_name
      }
    end

    let(:transcription_response_4) do
      {
        id: transcription_file_4.id,
        externalAppealId: appeal_3.uuid,
        docketNumber: transcription_file_4.docket_number,
        caseDetails: "#{transcription_file_4.hearing.appeal.appellant_or_veteran_name} " \
          "(#{transcription_file_4.hearing.appeal.veteran_file_number})",
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: hearing_3.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_4.hearing_type,
        fileStatus: transcription_file_4.file_status,
        fileName: transcription_file_4.file_name
      }
    end

    let(:transcription_response_4_completed) do
      {
        id: transcription_file_4.id,
        externalAppealId: appeal_3.uuid,
        docketNumber: transcription_file_4.docket_number,
        caseDetails: "#{transcription_file_4.hearing.appeal.appellant_or_veteran_name} " \
          "(#{transcription_file_4.hearing.appeal.veteran_file_number})",
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: hearing_3.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_4.hearing_type,
        fileStatus: transcription_file_4.file_status,
        fileName: transcription_file_4.file_name,
        workOrder: transcription_1.task_number,
        expectedReturnDate: transcription_package_1.expected_return_date.to_formatted_s(:short_date),
        returnDate: transcription_file_4.date_returned_box.to_formatted_s(:short_date),
        contractor: transcription_package_1.contractor.name
      }
    end

    let(:transcription_response_4_all) do
      {
        id: transcription_file_4.id,
        externalAppealId: appeal_3.uuid,
        docketNumber: transcription_file_4.docket_number,
        caseDetails: "#{transcription_file_4.hearing.appeal.appellant_or_veteran_name} " \
          "(#{transcription_file_4.hearing.appeal.veteran_file_number})",
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: hearing_3.hearing_day.scheduled_for.to_formatted_s(:short_date),
        hearingType: transcription_file_4.hearing_type,
        fileStatus: transcription_file_4.file_status,
        fileName: transcription_file_4.file_name,
        workOrder: transcription_1.task_number,
        uploadDate: transcription_file_4.date_upload_box.to_formatted_s(:short_date),
        returnDate: transcription_file_4.date_returned_box.to_formatted_s(:short_date),
        contractor: transcription_package_1.contractor.name
      }
    end

    it "returns a pagenated result" do
      get :transcription_file_tasks, params: { page_size: 2 }

      expected_response = {
        task_page_count: 2,
        tasks: {
          data: [transcription_response_4, transcription_response_3]
        },
        tasks_per_page: 2,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "returns second page of pagenated results" do
      get :transcription_file_tasks, params: { page: 2, page_size: 2 }

      expected_response = {
        task_page_count: 2,
        tasks: {
          data: [transcription_response_2, transcription_response_1]
        },
        tasks_per_page: 2,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by unassigned tab" do
      get :transcription_file_tasks, params: { tab: "Unassigned" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_3, transcription_response_2, transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 3
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by completed tab and adds extra fields" do
      get :transcription_file_tasks, params: { tab: "Completed" }
      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_4_completed]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by all files tab and adds extra fields" do
      get :transcription_file_tasks, params: { page_size: 1, tab: "All" }

      expected_response = {
        task_page_count: 4,
        tasks: {
          data: [transcription_response_4_all]
        },
        tasks_per_page: 1,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by case types" do
      filter = Rack::Utils.build_query({ col: "typesColumn", val: "AOD" })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_2, transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing dates between dates" do
      filter = Rack::Utils.build_query({ col: "hearingDateColumn", val: "between,2000-01-01,2015-12-31" })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_4, transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing dates before a date" do
      filter = Rack::Utils.build_query({ col: "hearingDateColumn", val: "before,2010-12-31," })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing dates after a date" do
      filter = Rack::Utils.build_query({ col: "hearingDateColumn", val: "after,2010-12-31," })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_3, transcription_response_2, transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 3
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing dates after a date" do
      filter = Rack::Utils.build_query({ col: "hearingDateColumn", val: "on,01/19/2014," })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing dates and handles an empty response" do
      filter = Rack::Utils.build_query({ col: "hearingDateColumn", val: "on,01/19/2025," })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 0,
        tasks: {
          data: []
        },
        tasks_per_page: 15,
        total_task_count: 0
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by hearing types" do
      filter = Rack::Utils.build_query({ col: "hearingTypeColumn", val: "Hearing" })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_4, transcription_response_2, transcription_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 3
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by status" do
      filter = Rack::Utils.build_query({ col: "statusColumn", val: file_status_retrieval })

      get :transcription_file_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by multiple fields" do
      filter_1 = Rack::Utils.build_query({ col: "typesColumn", val: "Original" })
      filter_2 = Rack::Utils.build_query({ col: "hearingTypeColumn", val: "LegacyHearing" })

      get :transcription_file_tasks, params: { filter: [filter_1, filter_2] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_3]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "orders by date column" do
      get :transcription_file_tasks, params: { sort_by: "hearingDateColumn", order: "desc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_3, transcription_response_2, transcription_response_1, transcription_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "orders by case type column" do
      get :transcription_file_tasks, params: { sort_by: "typesColumn", order: "asc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_1, transcription_response_2, transcription_response_4, transcription_response_3]
        },
        tasks_per_page: 15,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "combines ordering and filtering" do
      filter = Rack::Utils.build_query({ col: "typesColumn", val: "AOD" })

      get :transcription_file_tasks, params: { filter: [filter], sort_by: "hearingTypeColumn", order: "asc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_1, transcription_response_2]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by search query" do
      get :transcription_file_tasks, params: { search: "search-test" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [transcription_response_3]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end
  end

  describe "locking" do
    let!(:current_user) { User.authenticate!(roles: ["Transcriptions"]) }
    let!(:other_user) { create(:user) }
    let!(:current_time) { Time.zone.local(2024, 1, 17, 15, 37, 0).utc }

    let!(:transcription_file_1) do
      create(:transcription_file,
             locked_by_id: current_user.id, locked_at: current_time - 1.hour)
    end
    let!(:transcription_file_2) do
      create(:transcription_file,
             locked_by_id: other_user.id, locked_at: current_time - 1.hour)
    end
    let!(:transcription_file_3) do
      create(:transcription_file,
             locked_by_id: current_user.id, locked_at: current_time - 3.hours)
    end
    let!(:transcription_file_4) do
      create(:transcription_file,
             locked_by_id: other_user.id, locked_at: current_time - 3.hours)
    end
    let!(:transcription_file_5) do
      create(:transcription_file, locked_by_id: nil, locked_at: nil)
    end

    let(:transcription_file_1_info_response) do
      {
        id: transcription_file_1.id,
        docketNumber: "H" + transcription_file_1.docket_number,
        firstName: transcription_file_1.hearing.appellant_first_name,
        lastName: transcription_file_1.hearing.appellant_last_name,
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: transcription_file_1.hearing.scheduled_for.to_formatted_s(:short_date),
        appealType: "AMA",
        judge: "JudgeUser",
        regionalOffice: "Washington",
        hearingId: transcription_file_1.hearing.id
      }
    end

    let!(:transcription_file_6) do
      create(
        :transcription_file,
        hearing: create(:legacy_hearing),
        file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.success,
        hearing_type: "LegacyHearing"
      )
    end

    let(:transcription_file_6_info_response) do
      {
        id: transcription_file_6.id,
        docketNumber: "L" + transcription_file_6.docket_number,
        firstName: transcription_file_6.hearing.appellant_first_name,
        lastName: transcription_file_6.hearing.appellant_last_name,
        isAdvancedOnDocket: false,
        caseType: "Original",
        hearingDate: transcription_file_6.hearing.scheduled_for.to_formatted_s(:short_date),
        appealType: "Legacy",
        judge: nil,
        regionalOffice: "Washington",
        hearingId: transcription_file_6.hearing.id
      }
    end

    before do
      TranscriptionTeam.singleton.add_user(current_user)
      Timecop.freeze(current_time)
    end

    describe "GET locked" do
      it "returns a list of locked items including locked or selected status and skips unlocked items" do
        get :locked

        expected_response = [
          { id: transcription_file_1.id, status: "selected", message: "" },
          { id: transcription_file_2.id, status: "locked", message: "Locked by " + other_user.username }
        ].to_json

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end
    end

    describe "POST lock" do
      it "locks lockable items based on list of IDs passed in and returns all locked items" do
        post :lock, params: { file_ids: [transcription_file_2.id, transcription_file_5.id], status: true }

        expected_response = [
          { id: transcription_file_1.id, status: "selected", message: "" },
          { id: transcription_file_2.id, status: "locked", message: "Locked by " + other_user.username },
          { id: transcription_file_5.id, status: "selected", message: "" }
        ].to_json

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end

      it "unlocks lockable items based on list of IDs passed in and returns all locked items" do
        post :lock, params: { file_ids: [transcription_file_1.id, transcription_file_2.id], status: false }

        expected_response = [
          { id: transcription_file_2.id, status: "locked", message: "Locked by " + other_user.username }
        ].to_json

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end
    end

    describe "GET selected files info" do
      it "gives info for selected files for AMA" do
        get :selected_files_info, params: { file_ids: [transcription_file_1.id], status: true }

        expect(response.status).to eq(200)
        expect(response.body).to eq([transcription_file_1_info_response].to_json)
      end

      it "gives info for selected files for Legacy" do
        get :selected_files_info, params: { file_ids: [transcription_file_6.id], status: true }

        expect(response.status).to eq(200)
        expect(response.body).to eq([transcription_file_6_info_response].to_json)
      end

      it "gives info from only selected files" do
        get :selected_files_info, params: { file_ids: [transcription_file_1.id, transcription_file_4.id], status: true }

        expect(response.status).to eq(200)
        expect(
          JSON.parse(response.body).pluck("id")
        ).to eq(
          [transcription_file_4.id, transcription_file_1.id]
        ).or eq([transcription_file_1.id, transcription_file_4.id])
      end
    end
  end
end
