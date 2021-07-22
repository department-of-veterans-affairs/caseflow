# frozen_string_literal: true

require "models/concerns/has_virtual_hearing_examples"

describe Hearing, :postgres do
  it_should_behave_like "a model that can have a virtual hearing" do
    let(:instance_of_class) { create(:hearing, regional_office: "RO42") }
  end

  context "create" do
    let!(:hearing_day) { create(:hearing_day) }

    before do
      12.times do
        create(:hearing, hearing_day: hearing_day)
      end

      hearing_day.reload
    end

    it "prevents user from overfilling a hearing day" do
      expect do
        Hearing.create!(appeal: create(:appeal), hearing_day: hearing_day, scheduled_time: "8:30 am est")
      end.to raise_error(Hearing::HearingDayFull)
    end
  end

  context "disposition_editable" do
    let!(:hearing) { create(:hearing, :with_tasks) }
    subject { hearing.disposition_editable }

    context "when the hearing has an open disposition task" do
      it { is_expected.to eq(true) }
    end

    context "when the hearing has a cancelled disposition task" do
      before do
        hearing.hearing_task_association.hearing_task.update!(parent: create(:root_task))
        hearing.disposition_task.update!(status: Constants.TASK_STATUSES.cancelled)
      end

      it { is_expected.to eq(false) }
    end

    context "when the hearing has a disposition task with children" do
      let!(:transcription_task) { create(:transcription_task, parent: hearing.disposition_task) }

      it { is_expected.to eq(false) }
    end
  end

  context "#advance_on_docket_motion" do
    let!(:hearing) { create(:hearing, :with_tasks) }

    before do
      [false, false, true, false, false].each do |granted|
        AdvanceOnDocketMotion.create(
          user_id: create(:user).id,
          person_id: hearing.claimant_id,
          granted: granted,
          reason: Constants.AOD_REASONS.age,
          appeal: hearing.appeal
        )
      end
    end

    it "returns granted motion" do
      expect(hearing.advance_on_docket_motion["granted"]).to eq(true)
    end
  end

  context "assigned_to_vso?" do
    let!(:hearing) { create(:hearing, :with_tasks) }
    let!(:user) { create(:user, :vso_role) }
    let!(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
    let!(:vso) { create(:vso, participant_id: vso_participant_id) }
    let!(:track_veteran_task) { create(:track_veteran_task, appeal: hearing.appeal, assigned_to: vso) }
    let!(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = user

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: user.css_id, station_id: user.station_id).and_return(vso_participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(vso_participant_id).and_return(vso_participant_ids)
    end

    subject { hearing.assigned_to_vso?(user) }

    context "when the hearing is not assigned a vso" do
      let(:vso) do
        Vso.create(
          participant_id: "999",
          name: "Test VSO",
          url: "test-vso"
        )
      end

      it { is_expected.to eq(false) }
    end

    context "when the hearing is assigned a vso" do
      it { is_expected.to eq(true) }
    end
  end

  context "#hearing_location_or_regional_office" do
    subject { hearing.hearing_location_or_regional_office }

    context "hearing location is nil" do
      let(:hearing) { create(:hearing, regional_office: nil) }

      it "returns regional office" do
        expect(subject).to eq(hearing.regional_office)
      end
    end

    context "hearing location is not nil" do
      let(:hearing) { create(:hearing, regional_office: "RO42") }

      it "returns hearing location" do
        expect(subject).to eq(hearing.location)
      end
    end
  end

  context "#rescue_and_check_toggle_veteran_date_of_death_info" do
    let!(:hearing) { create(:hearing, :with_tasks) }

    subject { hearing.rescue_and_check_toggle_veteran_date_of_death_info }

    context "feature toggle disabled" do
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "feature toggle enabled" do
      before { FeatureToggle.enable!(:view_fnod_badge_in_hearings) }
      after { FeatureToggle.disable!(:view_fnod_badge_in_hearings) }

      it "returns non nil values" do
        expect(subject).not_to eq(nil)
        expect(subject.keys).to include(
          :veteran_full_name,
          :veteran_appellant_deceased,
          :veteran_death_date,
          :veteran_death_date_reported_at
        )
      end

      context "when error is thrown" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info)
            .and_raise(StandardError.new)
        end

        it "rescues error and nil" do
          expect(Raven).to receive(:capture_exception)
          expect(subject).to eq(nil)
        end
      end
    end
  end

  context "hearing email recipient" do
    shared_context "when there is a virtual hearing" do
      let!(:email_event) do
        create(
          :sent_hearing_email_event,
          email_address: email_address,
          recipient_role: recipient_role,
          hearing: hearing
        )
      end

      let!(:virtual_hearing) do
        VirtualHearing.create!(
          hearing: hearing,
          appellant_email: appellant_email,
          appellant_tz: appellant_tz,
          judge_email: judge_email,
          representative_email: representative_email,
          representative_tz: representative_tz,
          created_by: User.system_user
        )
      end

      it "backfills virtual hearing data and returns recipient", :aggregate_failures do
        expect(hearing.reload.email_recipients.empty?).to eq(true)
        expect(subject).not_to eq(nil)
        expect(subject.email_address).to eq(email_address)
        expect(subject.timezone).to eq(timezone)

        expect(email_event.reload.email_recipient).to eq(subject)
      end
    end

    shared_context "returns existing recipient" do
      let!(:email_recipient) do
        create(
          :hearing_email_recipient,
          type,
          hearing: hearing,
          email_address: email_address,
          timezone: timezone,
        )
      end

      it "returns exisiting recipient" do
        expect(subject).to eq(email_recipient)
      end
    end

    let(:hearing) { create(:hearing) }
    let(:appellant_email) { nil }
    let(:appellant_tz) { nil }
    let(:representative_email) { nil }
    let(:representative_tz) { nil }
    let(:judge_email) { nil }

    context "#appellant_recipient" do
      let(:type) { :appellant_hearing_email_recipient }
      let(:appellant_email) { "test1@email.com" }
      let(:appellant_tz) { "America/New_York" }
      let(:email_address) { appellant_email }
      let(:timezone) { appellant_tz }
      let(:recipient_role) { HearingEmailRecipient::RECIPIENT_ROLES[:veteran] }

      subject { hearing.reload.appellant_recipient }

      include_context "when there is a virtual hearing"
      context "when there is an exisiting recipient" do
        include_context "returns existing recipient"
      end
    end

    context "#representative_recipient" do
      let(:type) { :representative_hearing_email_recipient }
      let(:representative_email) { "test2@email.com" }
      let(:representative_tz) { "America/Los_Angeles" }
      let(:email_address) { representative_email }
      let(:timezone) { representative_tz }
      let(:recipient_role) { HearingEmailRecipient::RECIPIENT_ROLES[:representative] }

      subject { hearing.reload.representative_recipient }

      include_context "when there is a virtual hearing"
      context "when there is an exisiting recipient" do
        include_context "returns existing recipient"
      end
    end

    context "#judge_recipient" do
      let(:type) { :judge_hearing_email_recipient }
      let(:judge_email) { "test3@email.com" }
      let(:email_address) { judge_email }
      let(:timezone) { nil }
      let(:recipient_role) { HearingEmailRecipient::RECIPIENT_ROLES[:judge] }

      subject { hearing.reload.judge_recipient }

      include_context "when there is a virtual hearing"
      context "when there is an exisiting recipient" do
        include_context "returns existing recipient"
      end
    end
  end
end
