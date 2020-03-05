# frozen_string_literal: true

describe HearingsProfileHelper do
  let(:hearing_keys) do
    [
      :id,
      :type,
      :external_id,
      :created_by_timezone,
      :central_office_time_string,
      :scheduled_time_string,
      :scheduled_for,
      :scheduled_time
    ]
  end
  let!(:user) { create(:user) }
  let!(:ama_hearing) { create(:hearing) }
  let!(:ama_hearing2) { create(:hearing) }
  let!(:legacy_hearing) { create(:legacy_hearing) }

  subject { HearingsProfileHelper.profile_data(user) }

  context ".profile_data" do
    it "should return an object in the expected format" do
      expect(subject.keys).to match_array([:profile, :hearings])

      expect(subject[:profile].keys).to match_array(
        [:current_user_css_id, :current_user_timezone, :time_zone_name, :config_time_zone]
      )
      expect(subject[:profile].value?(nil)).to be_falsey

      expect(subject[:hearings].keys).to match_array(
        [:ama_hearings, :legacy_hearings]
      )

      expect(subject[:hearings][:ama_hearings].count).to eq 2
      expect(subject[:hearings][:ama_hearings].first.keys).to match_array hearing_keys
      expect(subject[:hearings][:ama_hearings].first.value?(nil)).to be_falsey

      expect(subject[:hearings][:legacy_hearings].count).to eq 1
      expect(subject[:hearings][:legacy_hearings].first.keys).to match_array hearing_keys
      expect(subject[:hearings][:legacy_hearings].first.value?(nil)).to be_falsey
    end
  end
end
