# frozen_string_literal: true

require "rails_helper"

describe QueueColumn do
  describe ".from_name" do
    subject { QueueColumn.from_name(column_name) }

    context "when the column name is null" do
      let(:column_name) { nil }

      it "return nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when the column name matches a column defined in the queue config" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name }

      it "return an instance of QueueColumn" do
        expect(subject).to be_a(QueueColumn)

        expect(subject.name).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name)
        expect(subject.sorting_table).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_table)
        expect(subject.sorting_columns).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_columns)
      end
    end
  end
end
