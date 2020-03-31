# frozen_string_literal: true

describe HearingDayRequestTypeQuery do
  subject { HearingDayRequestTypeQuery.new.call }

  context "with central hearing day" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: HearingDay::REQUEST_TYPES[:central]
      )
    end

    it "returns empty hash" do
      expect(subject).to be_empty
    end
  end

  context "with video hearing day" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        regional_office: "RO01",
        request_type: HearingDay::REQUEST_TYPES[:video]
      )
    end

    context "and no hearings" do
      it "returns empty hash" do
        expect(subject).to be_empty
      end
    end

    shared_examples_for "it returns correct hash with expected key and value" do |expected_type|
      it "returns a hash with the hearing day id as key and '#{expected_type}' as value" do
        expect(subject).to have_key(hearing_day.id)
        expect(subject[hearing_day.id]).to eq expected_type
      end
    end

    context "single ama video hearing" do
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }

      include_examples "it returns correct hash with expected key and value",
                       Hearing::HEARING_TYPES[:V]
    end

    context "single legacy video hearing" do
      let!(:legacy_hearing) { create(:legacy_hearing, hearing_day: hearing_day) }

      include_examples "it returns correct hash with expected key and value",
                       Hearing::HEARING_TYPES[:V]
    end

    context "mix of ama and legacy video hearings" do
      let!(:hearings) do
        [
          create(:hearing, hearing_day: hearing_day),
          create(:legacy_hearing, hearing_day: hearing_day)
        ]
      end

      include_examples "it returns correct hash with expected key and value",
                       Hearing::HEARING_TYPES[:V]
    end

    context "single ama virtual hearing" do
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: hearing) }

      include_examples "it returns correct hash with expected key and value",
                       COPY::VIRTUAL_HEARING_REQUEST_TYPE

      context "with a previously cancelled virtual hearing" do
        let!(:cancelled_virtual_hearing) { create(:virtual_hearing, :cancelled, hearing: hearing) }

        include_examples "it returns correct hash with expected key and value",
                         COPY::VIRTUAL_HEARING_REQUEST_TYPE
      end
    end

    context "single legacy virtual hearing" do
      let!(:legacy_hearing) { create(:legacy_hearing, hearing_day: hearing_day) }
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: legacy_hearing) }

      include_examples "it returns correct hash with expected key and value",
                       COPY::VIRTUAL_HEARING_REQUEST_TYPE

      context "with a previously cancelled virtual hearing" do
        let!(:cancelled_virtual_hearing) do
          create(:virtual_hearing, :cancelled, hearing: legacy_hearing)
        end

        include_examples "it returns correct hash with expected key and value",
                         COPY::VIRTUAL_HEARING_REQUEST_TYPE
      end
    end

    context "mix of legacy and ama and video and virtaul hearings" do
      let(:hearings) do
        [
          create(:hearing, hearing_day: hearing_day),
          create(:legacy_hearing, hearing_day: hearing_day)
        ]
      end
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: hearings[0]) }

      include_examples "it returns correct hash with expected key and value",
                       "Video, Virtual"
    end
  end
end
