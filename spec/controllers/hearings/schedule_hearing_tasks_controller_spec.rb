# frozen_string_literal: true

RSpec.describe Hearings::ScheduleHearingTasksController, :all_dbs, type: :controller do
  before do
    User.authenticate!(roles: ["System Admin"])
  end

  describe "GET schedule_hearing_tasks/:index" do
    let(:params) do
      {
        tab: "legacyAssignHearingsTab",
        page: "1",
        regional_office_key: closest_regional_office
      }
    end
    let!(:vacols_case1) do
      create(
        :case,
        bfcorlid: "#{veteran1.file_number}S",
        folder: create(:folder, tinum: "1545676"),
        bfregoff: "RO04",
        bfcurloc: "57",
        bfhr: "2",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let!(:vacols_case2) do
      create(
        :case,
        bfcorlid: "#{veteran2.file_number}S",
        folder: create(:folder, tinum: "1545678"),
        bfregoff: "RO04",
        bfcurloc: "57",
        bfhr: "2",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let!(:vacols_case3) do
      create(
        :case,
        bfcorlid: "#{veteran3.file_number}S",
        folder: create(:folder, tinum: "1545677"),
        bfregoff: "RO04",
        bfcurloc: "57",
        bfhr: "2",
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    let(:closest_regional_office) { "RO10" }
    let(:address) { "Fake Address" }
    let!(:veteran1) { create(:veteran) }
    let!(:veteran2) { create(:veteran) }
    let!(:veteran3) { create(:veteran) }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

    before do
      AppealRepository.create_schedule_hearing_tasks.each do |appeal|
        appeal.update(closest_regional_office: closest_regional_office)

        AvailableHearingLocations.create(
          appeal: appeal,
          address: address,
          distance: 0
        )
      end
      cache_appeals
    end

    subject { get :index, params: params }

    it "processes request successfully" do
      subject

      expect(response).to have_http_status(:success)
    end

    it "returns correct hash keys" do
      subject

      expect(JSON.parse(response.body).keys).to match_array(
        %w[tasks tasks_per_page task_page_count total_task_count docket_line_index]
      )
    end

    it "returns correct tasks in correct order" do
      subject

      expect(JSON.parse(response.body)["tasks"]["data"]
        .map { |task| task["attributes"]["veteran_file_number"] }).to eq(
          [veteran1.file_number, veteran3.file_number, veteran2.file_number]
        )
      expect(JSON.parse(response.body)["total_task_count"]).to eq(3)
      expect(JSON.parse(response.body)["tasks_per_page"]).to eq(15)
      expect(JSON.parse(response.body)["task_page_count"]).to eq(1)
    end
  end
end
