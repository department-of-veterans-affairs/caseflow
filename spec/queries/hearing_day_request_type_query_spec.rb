# frozen_string_literal: true

describe HearingDayRequestTypeQuery do
  subject { HearingDayRequestTypeQuery.new.call }

  before(:all) do
    Seeds::NotificationEvents.new.seed!
  end

  shared_examples_for "it returns correct hash with expected key and value" do |expected_type|
    it "returns a hash with the hearing day id as key and '#{expected_type}' as value" do
      expect(subject).to have_key(hearing_day.id)
      expect(subject[hearing_day.id]).to eq expected_type
    end
  end

  shared_examples_for "request type query for hearing day" do |expected_type|
    let!(:hearing_day) do
      create(
        :hearing_day,
        regional_office: regional_office,
        request_type: request_type
      )
    end

    context "and no hearings" do
      it "returns empty hash" do
        expect(subject).to be_empty
      end
    end

    context "single ama #{expected_type.downcase} hearing" do
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }

      include_examples "it returns correct hash with expected key and value", expected_type
    end

    context "single legacy #{expected_type.downcase} hearing" do
      let!(:legacy_hearing) { create(:legacy_hearing, hearing_day: hearing_day) }

      include_examples "it returns correct hash with expected key and value", expected_type
    end

    context "mix of ama and legacy video hearings" do
      let!(:hearings) do
        [
          create(:hearing, hearing_day: hearing_day),
          create(:legacy_hearing, hearing_day: hearing_day)
        ]
      end

      include_examples "it returns correct hash with expected key and value", expected_type
    end

    context "single ama virtual hearing" do
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: hearing) }

      include_examples "it returns correct hash with expected key and value",
                       COPY::VIRTUAL_HEARING_REQUEST_TYPE

      context "with a previously cancelled virtual hearing" do
        let!(:cancelled_virtual_hearing) { create(:virtual_hearing, status: :cancelled, hearing: hearing) }

        include_examples "it returns correct hash with expected key and value",
                         COPY::VIRTUAL_HEARING_REQUEST_TYPE
      end
    end

    context "single virtual hearing that has been held" do
      let(:hearing_day) do
        create(
          :hearing_day,
          regional_office: regional_office,
          request_type: request_type,
          scheduled_for: Time.zone.today - 1.week
        )
      end
      let(:hearing) do
        create(
          :hearing,
          :held,
          hearing_day: hearing_day
        )
      end
      # Virtual hearing has already been cleaned up successfully.
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          :all_emails_sent,
          conference_deleted: true,
          hearing: hearing,
          status: :active
        )
      end

      context "hearing is an ama hearing" do
        it "sanity check: hearing is virtual" do
          expect(hearing.reload.virtual?).to be true
        end

        include_examples "it returns correct hash with expected key and value",
                         COPY::VIRTUAL_HEARING_REQUEST_TYPE
      end

      context "hearing is a legacy hearing" do
        let(:disposition) { :H }
        let(:hearing) { create(:legacy_hearing, disposition: disposition, hearing_day: hearing_day) }

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
          create(:virtual_hearing, status: :cancelled, hearing: legacy_hearing)
        end

        include_examples "it returns correct hash with expected key and value",
                         COPY::VIRTUAL_HEARING_REQUEST_TYPE
      end
    end

    context "mix of legacy and ama and #{expected_type.downcase} and virtual hearings" do
      let(:hearings) do
        [
          create(:hearing, hearing_day: hearing_day),
          create(:legacy_hearing, hearing_day: hearing_day)
        ]
      end
      let!(:virtual_hearing) { create(:virtual_hearing, :initialized, hearing: hearings[0]) }

      include_examples "it returns correct hash with expected key and value",
                       "#{expected_type}, Virtual"
    end
  end

  context "with central hearing day" do
    let(:request_type) { HearingDay::REQUEST_TYPES[:central] }
    let(:regional_office) { nil }

    include_examples "request type query for hearing day", Hearing::HEARING_TYPES[:C]
  end

  context "with video hearing day" do
    let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
    let(:regional_office) { "RO01" }

    include_examples "request type query for hearing day", Hearing::HEARING_TYPES[:V]
  end
end
