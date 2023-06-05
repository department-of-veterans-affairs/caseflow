# frozen_string_literal: true

RSpec.describe Hearings::ScheduleHearingTasksColumnsController, :all_dbs, type: :controller do
  before do
    User.authenticate!(roles: ["System Admin"])
  end

  describe "GET schedule_hearing_columns_tasks/:index" do
    let(:regional_office_key) { "RO17" }
    let(:appeal) do
      create(
        :appeal,
        closest_regional_office: regional_office_key
      )
    end
    let!(:poa) do
      create(
        :bgs_power_of_attorney,
        :with_name_cached,
        appeal: appeal,
        claimant_participant_id: appeal.claimant.participant_id
      )
    end

    let!(:hearing_location) do
      create(
        :available_hearing_locations,
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        city: "New York",
        state: "NY",
        facility_id: "vba_372",
        distance: 9
      )
    end
    let(:assignee) { HearingsManagement.singleton }
    let!(:task) { create(:schedule_hearing_task, assigned_to: assignee, appeal: appeal) }
    let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

    subject do
      get :index, params:
      {
        tab: Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME,
        regional_office_key: regional_office_key
      }
    end

    it "should process the request successfully" do
      subject

      expect(response).to have_http_status(:success)
    end

    it "returns correct hash key" do
      cache_appeals
      subject

      expect(JSON.parse(response.body).keys).to match_array(["columns"])
    end

    it "returns correct result" do
      cache_appeals
      subject

      expect(JSON.parse(response.body)["columns"].first["name"]).to eq("powerOfAttorneyName")
      expect(JSON.parse(response.body)["columns"].first["filter_options"]).to match_array(
        [{ "value" => URI.escape(URI.escape(appeal.representative_name)),
           "displayText" => "#{appeal.representative_name} (1)" }]
      )
      expect(JSON.parse(response.body)["columns"].second["name"]).to eq("suggestedLocation")
      expect(JSON.parse(response.body)["columns"].second["filter_options"]).to match_array(
        [{ "value" => URI.escape(URI.escape(hearing_location.formatted_location)),
           "displayText" => "#{hearing_location.formatted_location} (1)" }]
      )
    end
  end
end
