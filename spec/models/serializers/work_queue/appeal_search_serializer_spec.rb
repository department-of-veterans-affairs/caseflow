# frozen_string_literal: true

require "rails_helper"

describe WorkQueue::AppealSearchSerializer, :all_dbs do
  describe "#assigned_to_location" do
    context "when appeal status is restricted" do
      let!(:judge_user) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_J") }
      let(:appeal) { create(:appeal, :assigned_to_judge, associated_judge: judge_user) }

      before do
        User.authenticate!(user: judge_user)
      end

      subject { described_class.new(appeal, params: { user: judge_user }) }

      context "and user is a board judge" do
        it "shows CSS ID" do
          expect(subject.serializable_hash[:data][:attributes][:assigned_to_location])
            .to eq(appeal.assigned_to_location)
        end
      end

      context "when appeal status is restricted" do
        let(:appeal) { create(:appeal, :at_attorney_drafting) }
        let!(:attorney_user) { create(:user) }
        let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

        before do
          User.authenticate!(user: attorney_user)
        end

        subject { described_class.new(appeal, params: { user: attorney_user }) }

        context "and user is a board attorney" do
          it "shows CSS ID" do
            expect(subject.serializable_hash[:data][:attributes][:assigned_to_location])
              .to eq(appeal.assigned_to_location)
          end
        end
      end

      context "when appeal status is restricted" do
        let!(:judge_user) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_J") }
        let(:appeal) { create(:appeal, :at_judge_review, associated_judge: judge_user) }
        let!(:hearings_coordinator_user) do
          coordinator = create(:hearings_coordinator)
          HearingsManagement.singleton.add_user(coordinator)
          coordinator
        end

        before do
          User.authenticate!(user: hearings_coordinator_user)
        end

        subject { described_class.new(appeal, params: { user: hearings_coordinator_user }) }

        context "and user is a hearings coordinator" do
          it "shows CSS ID" do
            expect(subject.serializable_hash[:data][:attributes][:assigned_to_location])
              .to eq(appeal.assigned_to_location)
          end
        end
      end

      context "when user is a vso representative" do
        let(:appeal) { create(:appeal, :at_attorney_drafting) }
        let(:vso_user) { create(:user, :vso_role) }

        before do
          User.authenticate!(user: vso_user)
        end

        subject { described_class.new(appeal, params: { user: vso_user }) }

        it "does not show CSS ID to VSO user" do
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

      it "shows CSS ID to VSO user" do
        expect(subject.serializable_hash[:data][:attributes][:assigned_to_location])
          .to eq(appeal.assigned_to_location)
      end
    end
  end
end
