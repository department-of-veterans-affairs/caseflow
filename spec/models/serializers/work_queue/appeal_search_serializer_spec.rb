# frozen_string_literal: true

require "rails_helper"

describe WorkQueue::AppealSearchSerializer, :all_dbs do
  describe "#assigned_to_location" do
    context "when appeal status is restricted" do
      let(:appeal) { create(:appeal, :at_attorney_drafting) }
      let!(:judge_user) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_J") }

      before do
        User.authenticate!(user: judge_user)
      end

      subject { described_class.new(appeal, params: { user: judge_user }) }

      context "when user is a judge, attorney, or hearing coordinator" do
        it "shows Judge CSS ID" do
          expect(subject.serializable_hash[:data][:attributes][:assigned_to_location]).to eq(appeal.assigned_to_location)
        end
      end

      context "when user is a vso representative" do
        let(:vso_user) { create(:user, :vso_role) }
        let(:appeal) { create(:appeal, :at_attorney_drafting) }

        before do
          User.authenticate!(user: vso_user)
        end

        subject { described_class.new(appeal, params: { user: vso_user }) }

        it "does not show Judge CSS ID" do
          expect(subject.serializable_hash[:data][:attributes][:assigned_to_location]).to be_nil
        end
      end
    end

    context "when appeal status is not restricted" do
      let(:appeal) { create(:appeal, :with_pre_docket_task) }
      let(:vso_user) { create(:user, :vso_role) }

      before do
        User.authenticate!(user: vso_user)
      end

      subject { described_class.new(appeal, params: { user: vso_user }) }

      it "shows Judge CSS ID to VSO user" do
        expect(subject.serializable_hash[:data][:attributes][:assigned_to_location]).to eq(appeal.assigned_to_location)
      end
    end
  end
end
