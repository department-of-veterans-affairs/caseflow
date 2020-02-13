# frozen_string_literal: true

describe AssignHearing do
  let(:tab) { AssignHearing.new(params) }
  let(:regional_office_key) { "RO18" }
  let(:assignee) { HearingsManagement.singleton }
  let(:params) do
    {
      appeal_type: Appeal.name,
      regional_office_key: regional_office_key
    }
  end
  let(:appeal) do
    create(
      :appeal,
      closest_regional_office: regional_office_key
    )
  end

  let!(:hearing_location1) do
    create(
      :available_hearing_locations,
      appeal_id: appeal.id,
      appeal_type: "Appeal",
      city: "New York",
      state: "NY",
      facility_id: "vba_372",
      facility_type: "va_benefits_facility",
      distance: 9
    )
  end

  let!(:hearing_location2) do
    create(
      :available_hearing_locations,
      appeal_id: appeal.id,
      appeal_type: "Appeal",
      city: "San Francisco",
      state: "CA",
      distance: 100
    )
  end

  let!(:task1) { create(:schedule_hearing_task, assigned_to: assignee, appeal: appeal) }
  let!(:task2) { create(:schedule_hearing_task, assigned_to: assignee, appeal: appeal) }

  let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

  describe ".tasks" do
    subject { tab.tasks }

    it "returns correct tasks" do
      cache_appeals
      expect(subject.select(&:id)).to include(task1, task2)
    end
  end

  describe ".power_of_attorney_name_options" do
    subject { tab.power_of_attorney_name_options }

    it "returns correct options" do
      cache_appeals

      expect(subject.first[:value]).to eq(URI.escape(URI.escape(appeal.representative_name)))
      expect(subject.first[:displayText]).to eq("#{appeal.representative_name} (2)")
    end
  end

  describe ".suggested_location_options" do
    subject { tab.suggested_location_options }

    it "returns correct options" do
      cache_appeals

      expect(subject.first[:value]).to eq(URI.escape(URI.escape(hearing_location1.formatted_location)))
      expect(subject.first[:displayText]).to eq("#{hearing_location1.formatted_location} (2)")
    end
  end

  describe ".columns" do
    subject { tab.columns }

    it "returns columns with the correct keys" do
      expect(subject.first.keys).to match_array([:name, :filter_options])
    end
  end

  describe ".to_hash" do
    subject { tab.to_hash }

    it "returns a hash with the correct key" do
      expect(subject.keys).to match_array([:columns])
    end
  end
end
