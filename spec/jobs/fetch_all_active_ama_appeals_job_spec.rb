# frozen_string_literal: true

describe FetchAllActiveAmaAppealsJob, type: :job do
  include ActiveJob::TestHelper

  subject { FetchAllActiveAmaAppealsJob.new }

  describe "#perform" do
    it "sets the USER and Perfoms the Job" do
      expect(RequestStore[:current_user]).to eq(nil)
      subject.perform
      expect(RequestStore[:current_user]).to eq(User.system_user)
    end
    it "calls #find_and_create_appeal_state_for_active_ama_appeals" do
      expect(subject).to receive(:find_and_create_appeal_state_for_active_ama_appeals)
      subject.perform
    end
  end

  describe "#find_and_create_appeal_state_for_active_ama_appeals" do
    context "when there are only CLOSED AMA Appeals in the database" do
      let!(:closed_ama_appeals) do
        Array.new(5) { create(:appeal, :with_completed_root_task) }
      end
      it "no records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(0)
      end
    end

    context "when there are only OPEN AMA Appeals in the database" do
      let!(:open_ama_appeals) do
        Array.new(5) { create(:appeal, :active) }
      end
      it "5 records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(5)
      end
    end

    context "when there are both OPEN & CLOSED AMA Appeals in the database" do
      let!(:open_ama_appeals) do
        Array.new(5) { create(:appeal, :active) }
      end
      let!(:closed_ama_appeals) do
        Array.new(5) { create(:appeal, :with_completed_root_task) }
      end
      it "only OPEN Legacy Appeal records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.map(&:appeal_id)).to eq(open_ama_appeals.map(&:id))
        expect(AppealState.all.count).to eq(5)
      end
    end
  end

  describe "#add_record_to_appeal_states_table" do
    let!(:legacy_appeal) { create(:legacy_appeal) }
    let(:error) { StandardError }
    context "When an error is raised" do
      it "will log error and continue" do
        allow(Rails.logger).to receive(:error)
        allow(subject).to receive(:map_appeal_ihp_state).with(legacy_appeal).and_raise(error)
        subject.send(:add_record_to_appeal_states_table, legacy_appeal)
        expect(Rails.logger).to have_received(:error).with(
          "\e[31m#{legacy_appeal&.class} ID #{legacy_appeal&.id} was unable to create an appeal_states record "\
          "because of #{error}\e[0m"
        )
      end
    end
  end

  # RSPECS
  # Test for multiple hearings, hearing cancelled (true), hearing not cancelled(false)
  # describe "#map_appeal_hearing_withdrawn_state" do
  #   context "when there is an active AMA Appeal with a hearing state of withdrawn" do
  #     let!(:open_ama_appeal_with_hearing_withdrawn) { create(:appeal, :active, :hearings, :disposition) }
  #     it "a single record will be inserted into the Appeal States table" do
  #       subject.perform
  #       expect(
  #         AppealState.find_by(
  #           appeal_id: open_ama_appeal_with_hearing_withdrawn.id,
  #           appeal_type: open_ama_appeal_with_hearing_withdrawn.class.to_s
  #         ).appeal_id
  #       ).to eq(open_ama_appeal_with_hearing_withdrawn.id)
  #       expect(AppealState.all.count).to eq(1)
  #     end
  #
  #   end

  # end

end
