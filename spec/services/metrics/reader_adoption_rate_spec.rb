# frozen_string_literal: true

describe Metrics::ReaderAdoptionRate do
  let(:user) { create(:user) }
  let(:start_date) { Time.zone.now - 45.days }
  let(:end_date) { Time.zone.now - 15.days }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }

  subject { Metrics::ReaderAdoptionRate.new(date_range).call }

  context "when some decisions were made outside the date range" do
    shared_examples "decisions made using Reader" do
      |descr, ama_reader_cnt, ama_non_reader_cnt, legacy_reader_cnt, legacy_non_reader_cnt, rate|
      context "when the environment is set up properly" do
        before do
          # Create some number of AMA appeals decisions with Reader views outside of the date range.
          create_list(:decision_document, rand(1..7), decision_date: start_date - 8.days).each do |doc|
            AppealView.create(appeal: doc.appeal, user: user)
          end

          create_list(:decision_document, ama_reader_cnt, decision_date: start_date + 1.day).each do |doc|
            AppealView.create(appeal: doc.appeal, user: user)
          end
          create_list(:decision_document, ama_non_reader_cnt, decision_date: start_date + 1.day)

          # FactoryBot.create_list() does not work here because it re-uses the same VACOLS::Case. Use a loop instead.
          legacy_reader_cnt.times do
            doc = create(
              :decision_document,
              appeal: create(:legacy_appeal, vacols_case: create(:case)),
              decision_date: start_date + 1.day
            )
            AppealView.create(appeal: doc.appeal, user: user)
          end
          legacy_non_reader_cnt.times do
            create(
              :decision_document,
              appeal: create(:legacy_appeal, vacols_case: create(:case)),
              decision_date: start_date + 1.day
            )
          end
        end

        it "calculates the expected rate when #{descr}" do
          expect(subject).to eq(rate)
        end
      end
    end

    include_examples "decisions made using Reader", "no decisions made using Reader", 0, 3, 0, 1, 0
    include_examples "decisions made using Reader", "some AMA decision made using Reader", 2, 4, 0, 2, 0.25
    include_examples "decisions made using Reader", "some legacy decision made using Reader", 0, 5, 2, 3, 0.2
    include_examples "decisions made using Reader", "some decisions of both made using Reader", 3, 1, 1, 3, 0.5
    include_examples "decisions made using Reader", "all decisions made using Reader", 2, 0, 4, 0, 1.0
  end
end
