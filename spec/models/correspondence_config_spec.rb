# frozen_string_literal: true

describe CorrespondenceConfig, :postgres do
  describe ".to_hash" do
    let(:assignee) { create(:organization) }
    let(:user) { create(:user) }

    subject { CorrespondenceConfig.new(assignee: assignee).to_hash }

    describe "shape of the returned hash" do
      it "returns the correct top level keys in the response" do
        expect(subject.keys).to match_array([:table_title, :active_tab, :tasks_per_page, :use_task_pages_api, :tabs])
      end
    end

    describe "title" do
      context "when assigned to an org" do
        it "is formatted as expected" do
          expect(subject[:table_title]).to eq("Correspondence cases")
        end
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "is formatted as expected" do
          expect(subject[:table_title]).to eq("Your correspondence")
        end
      end
    end

    describe "active_tab" do
      it "is the unassigned tab" do
        expect(subject[:active_tab]).to eq("correspondence_unassigned")
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "is the assigned tab" do
          expect(subject[:active_tab]).to eq("correspondence_assigned")
        end
      end
    end
  end
end
