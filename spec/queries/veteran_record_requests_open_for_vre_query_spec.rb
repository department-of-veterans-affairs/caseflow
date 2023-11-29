# frozen_string_literal: true

describe VeteranRecordRequestsOpenForVREQuery do
  describe ".call" do
    subject(:call) { described_class.call }

    context "when there are no VeteranRecordRequests" do
      let!(:task) { create(:task) }

      it "is none" do
        result = call

        expect(result).to be_a_kind_of(ActiveRecord::Relation)
        expect(result).to be_none
      end
    end

    context "when there are VeteranRecordRequests" do
      let!(:cancelled_for_vre) { create(:veteran_record_request_task, :cancelled, assigned_to: vre_business_line) }
      let!(:complete_for_vre) { create(:veteran_record_request_task, :completed, assigned_to: vre_business_line) }

      let!(:assigned_for_vre) { create(:veteran_record_request_task, assigned_to: vre_business_line) }
      let!(:in_progress_for_vre) { create(:veteran_record_request_task, :in_progress, assigned_to: vre_business_line) }
      let!(:on_hold_for_vre) { create(:veteran_record_request_task, :on_hold, assigned_to: vre_business_line) }

      let!(:assigned) { create(:veteran_record_request_task, assigned_to: non_vre_organization) }
      let!(:in_progress) { create(:veteran_record_request_task, :in_progress, assigned_to: non_vre_organization) }
      let!(:on_hold) { create(:veteran_record_request_task, :on_hold, assigned_to: non_vre_organization) }

      let(:vre_business_line) { create(:vre_business_line) }
      let(:non_vre_organization) { create(:organization) }

      it "only returns those that are both open and assigned to the VRE business line" do
        result = call

        expect(result).to be_a_kind_of(ActiveRecord::Relation)
        expect(result).to contain_exactly(
          assigned_for_vre,
          in_progress_for_vre,
          on_hold_for_vre
        )
      end
    end
  end
end
