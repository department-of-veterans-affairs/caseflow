# frozen_string_literal: true

describe Test::HearingsProfileHelper do
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

  # Reno regional office (America/Los_Angeles)
  let(:hearing_day) do
    create(
      :hearing_day,
      regional_office: "RO54",
      request_type: HearingDay::REQUEST_TYPES[:video],
      scheduled_for: Time.zone.now.to_date + 2.weeks
    )
  end
  let(:ama_hearing1) { create(:hearing, hearing_day: hearing_day) }
  let(:hearing_task1) { create(:hearing_task, appeal: ama_hearing1.appeal) }
  let!(:association1) { create(:hearing_task_association, hearing: ama_hearing1, hearing_task: hearing_task1) }
  let!(:disposition_task1) do
    create(:assign_hearing_disposition_task, parent: hearing_task1, appeal: ama_hearing1.appeal)
  end

  # Detroit regional office (America/New_York)
  let(:ama_hearing2) { create(:hearing, regional_office: "RO29") }
  let(:hearing_task2) { create(:hearing_task, appeal: ama_hearing2.appeal) }
  let!(:association2) { create(:hearing_task_association, hearing: ama_hearing2, hearing_task: hearing_task2) }
  let!(:disposition_task2) do
    create(:assign_hearing_disposition_task, parent: hearing_task2, appeal: ama_hearing2.appeal)
  end

  # Oakland regional office (America/Los_Angeles)
  let(:legacy_hearing) { create(:legacy_hearing, regional_office: "RO43") }
  let(:hearing_task3) { create(:hearing_task, appeal: legacy_hearing.appeal) }
  let!(:association3) { create(:hearing_task_association, hearing: legacy_hearing, hearing_task: hearing_task3) }
  let!(:disposition_task3) do
    create(:assign_hearing_disposition_task, parent: hearing_task3, appeal: legacy_hearing.appeal)
  end
  let(:params) {}

  subject { Test::HearingsProfileHelper.profile_data(user, **params) }

  context ".profile_data" do
    let(:params) { { limit: 2, after: Time.zone.now - 1.day } }

    it "returns an object in the expected format, not including hearings in eastern time" do
      expect(subject.keys).to match_array([:profile, :hearings])

      expect(subject[:profile].keys).to match_array(
        [:current_user_css_id, :current_user_timezone, :time_zone_name, :config_time_zone]
      )
      expect(subject[:profile].value?(nil)).to be_falsey

      expect(subject[:hearings].keys).to match_array(
        [:ama_hearings, :legacy_hearings]
      )

      expect(subject[:hearings][:ama_hearings].count).to eq 1
      expect(subject[:hearings][:ama_hearings].first.keys).to match_array hearing_keys
      expect(subject[:hearings][:ama_hearings].first.value?(nil)).to be_falsey

      expect(subject[:hearings][:legacy_hearings].count).to eq 1
      expect(subject[:hearings][:legacy_hearings].first.keys).to match_array hearing_keys
      expect(subject[:hearings][:legacy_hearings].first.value?(nil)).to be_falsey
    end

    context "with a limit of 1" do
      let(:params) { { limit: 1, after: Time.zone.now - 1.day } }

      it "returns one of each type of hearing" do
        expect(subject[:hearings][:ama_hearings].count).to eq 1
        expect(subject[:hearings][:legacy_hearings].count).to eq 1
      end
    end

    context "with after in the future" do
      let(:params) { { limit: 2, after: Time.zone.now + 1.week } }

      it "returns only the hearing scheduled after that date" do
        expect(subject[:hearings][:ama_hearings].count).to eq 1
        expect(subject[:hearings][:legacy_hearings].count).to eq 0
        expect(subject[:hearings][:ama_hearings].first[:external_id]).to eq ama_hearing1.external_id
      end
    end

    context "including hearings in eastern time" do
      let(:params) { { limit: 2, after: Time.zone.now - 1.day, include_eastern: true } }

      it "returns all the hearings" do
        expect(subject[:hearings][:ama_hearings].count).to eq 2
        expect(subject[:hearings][:legacy_hearings].count).to eq 1
      end
    end
  end
end
