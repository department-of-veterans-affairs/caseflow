# frozen_string_literal: true

describe CorrespondenceConfig, :postgres do
  before do
    RequestStore[:current_user] = user
  end

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
          expect(subject[:table_title]).to eq("Correspondence Cases")
        end
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "is formatted as expected" do
          expect(subject[:table_title]).to eq("Your Correspondence")
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

    describe "tabs array" do
      context "when assigned to an organization" do
        it "has the correct tabs" do
          expect(subject[:tabs].map do |tab|
            tab[:label]
          end).to eq(%w[Unassigned Action\ Required Pending Assigned Completed])
        end

        it "tabs have the correct columns" do
          expect(subject[:tabs].find { |tab| tab[:label] == "Unassigned" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[checkboxColumn veteranDetails packageDocTypeColumn vaDor daysWaitingCorrespondence notes])

          expect(subject[:tabs].find { |tab| tab[:label] == "Action Required" }[:columns]
          .map { |column| column[:name] })
            .to eq(
              %w[veteranDetails packageDocTypeColumn vaDor daysWaitingCorrespondence assignedByColumn actionType notes]
            )

          expect(subject[:tabs].find { |tab| tab[:label] == "Pending" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[veteranDetails packageDocTypeColumn vaDor daysWaitingCorrespondence taskColumn assignedToColumn])

          expect(subject[:tabs].find { |tab| tab[:label] == "Assigned" }[:columns]
          .map { |column| column[:name] })
            .to eq(
              %w[
                checkboxColumn veteranDetails packageDocTypeColumn
                vaDor daysWaitingCorrespondence taskColumn assignedToColumn notes
              ]
            )

          expect(subject[:tabs].find { |tab| tab[:label] == "Completed" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[veteranDetails packageDocTypeColumn vaDor correspondenceCompletedDateColumn notes])
        end
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "has the correct tabs" do
          expect(subject[:tabs].map do |tab|
            tab[:label]
          end).to eq(%w[Assigned In\ Progress Completed])
        end

        it "tabs have the correct columns" do
          expect(subject[:tabs].find { |tab| tab[:label] == "Assigned" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[veteranDetails packageDocTypeColumn vaDor daysWaitingCorrespondence notes])

          expect(subject[:tabs].find { |tab| tab[:label] == "In Progress" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[veteranDetails packageDocTypeColumn vaDor taskColumn daysWaitingCorrespondence notes])

          expect(subject[:tabs].find { |tab| tab[:label] == "Completed" }[:columns]
          .map { |column| column[:name] })
            .to eq(%w[veteranDetails packageDocTypeColumn vaDor correspondenceCompletedDateColumn notes])
        end
      end
    end
  end
end
