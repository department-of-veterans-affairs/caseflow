# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe QueueColumn, :all_dbs do
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

        expect(subject.filterable).to eq(true)
        expect(subject.name).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name)
        expect(subject.sorting_table).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_table)
        expect(subject.sorting_columns).to eq(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.sorting_columns)
      end
    end
  end

  describe ".format_option_label" do
    subject { QueueColumn.format_option_label(label, count) }

    let(:count) { rand(100) }

    context "when label is null" do
      let(:label) { nil }

      it "returns the special blank value" do
        expect(subject).to eq("#{COPY::NULL_FILTER_LABEL} (#{count})")
      end
    end

    context "when label is a string with some length" do
      let(:label) { Generators::Random.word_characters(rand(1..20)) }

      it "returns the properly formatted option label" do
        expect(subject).to eq("#{label} (#{count})")
      end
    end
  end

  describe ".filter_option_hash" do
    subject { QueueColumn.filter_option_hash(value, label) }

    let(:label) { Generators::Random.word_characters(rand(1..20)) }

    def match_encoding(str)
      URI.escape(URI.escape(str))
    end

    context "when input value is null" do
      let(:value) { nil }

      it "changes the null value to the special blank field value" do
        expect(subject[:value]).to eq(match_encoding(COPY::NULL_FILTER_LABEL))
      end

      it "does not alter the input label" do
        expect(subject[:label]).to eq(label)
      end
    end

    context "when input value is a string that contains special characters" do
      let(:value) { "Winston-Salem, N.Car." }

      it "properly encodes the value" do
        expect(subject[:value]).to eq(match_encoding(value))
      end
    end
  end

  describe ".filter_options" do
    subject { QueueColumn.from_name(column_name).filter_options(tasks) }

    context "when the column is not filterable" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name }
      let(:tasks) { create_list(:task, 5) }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "for the case type column" do
      let(:column_name) { Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name }
      let(:tasks) { Task.where(id: create_list(:task, 5).map(&:id)) }
      let(:aod_count) { 3 }

      before do
        tasks.each_with_index do |task, index|
          create(
            :cached_appeal,
            appeal_type: task.appeal.class.name,
            appeal_id: task.appeal.id,
            is_aod: (index < aod_count),
            case_type: VACOLS::Case::TYPES[(index + 1).to_s]
          )
        end
      end

      it "returns an array that includes AOD option" do
        option = QueueColumn.filter_option_hash("is_aod", QueueColumn.format_option_label("AOD", aod_count))
        expect(subject).to include(option)
      end

      it "returns an array with all present case types" do
        (1..5).map do |index|
          type_name = VACOLS::Case::TYPES[index.to_s]
          option = QueueColumn.filter_option_hash(type_name, QueueColumn.format_option_label(type_name, 1))

          expect(subject).to include(option)
        end
      end
    end
  end
end
