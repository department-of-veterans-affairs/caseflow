# frozen_string_literal: true

describe UserCorrespondenceConfig, :postgres do
  describe ".to_hash" do
    let(:user) { create(:user) }

    subject { described_class.new(assignee: user).to_hash }

    describe "shape of the returned hash" do
      it "returns the correct top level keys in the response" do
        expect(subject.keys).to match_array([:table_title, :active_tab, :tasks_per_page, :use_task_pages_api, :tabs])
      end
    end

    describe "title" do
      it "is formatted as expected" do
        expect(subject[:table_title]).to eq("Your correspondence")
      end
    end

    describe "active_tab" do
      it "is the assigned tab" do
        expect(subject[:active_tab]).to eq("correspondence_assigned")
      end
    end

    describe "tabs array" do
      it "has the correct tabs" do
        expect(subject[:tabs].map do |tab|
          tab[:label]
        end).to eq(%w[Assigned In\ Progress Completed])
      end

      it "tabs have the correct columns" do
        expect(subject[:tabs].find { |tab| tab[:label] == "Assigned" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor daysWaitingCorrespondence notes])

        expect(subject[:tabs].find { |tab| tab[:label] == "In Progress" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor taskColumn daysWaitingCorrespondence notes])

        expect(subject[:tabs].find { |tab| tab[:label] == "Completed" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor completedDateColumn notes])
      end
    end
  end
end
