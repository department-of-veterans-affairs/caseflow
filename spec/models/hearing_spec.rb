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
          reason: "age"
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
end
