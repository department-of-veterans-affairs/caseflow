# frozen_string_literal: true

describe Hearings::TravelBoardHearingSyncJob do
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:vacols_ids) { %w[123450 123451 123452 123453 123454 123455 123456 123457 123458 123459] }
  let(:new_caseflow_vacols_ids) { %w[123450 123451 123452 123453 123455 123456 123458 123459] }
  let(:legacy_appeal) { create(:legacy_appeal) }
  let(:existing_caseflow_vacols_ids) { LegacyAppeal.all.pluck(:vacols_id) }
  # rubocop:disable Style/BlockDelimiters
  let(:cases) {
    create_list(:case, 10) do |vacols_case, i|
      bfhr = (i == 4 || i == 7) ? "1" : VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value]
      vacols_case.update!(
        bfkey: vacols_ids[i],
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        bfhr: bfhr
      )
    end
  }
  # rubocop:enable Style/BlockDelimiters

  describe "#perform" do
    subject { Hearings::TravelBoardHearingSyncJob.new }

    before do
      current_user
      vacols_ids
      cases
      legacy_appeal
    end

    context "no environment variable provided" do
      it "limit parameter should default to 250 when fetching" do
        expect(subject).to receive(:fetch_vacols_travel_board_appeals).with(250)
        subject.perform
      end

      it "fetches and creates travel board legacy appeals that were not in caseflow before" do
        expect(subject.send(:fetch_vacols_travel_board_appeals, 250)
          .pluck(:vacols_id)).to eq(new_caseflow_vacols_ids)
        subject.perform
      end

      it "creates task trees for the newly created legacy appeals" do
        subject.perform
        expect(ScheduleHearingTask.all.count).to eq(new_caseflow_vacols_ids.length)
      end
    end

    context "Exceptions raised during processes" do
      before do
        Hearings::TravelBoardHearingSyncJob::JOB_ATTR = nil
      end
      it "logs out error when exception occurs when creating new legacy appeals" do
        allow(AppealRepository).to receive(:build_appeal).and_raise(StandardError)
        expect(Rails.logger).to receive(:error).at_least(:once)
        subject.perform
      end

      it "logs out error when exception occurs when creating new task trees" do
        allow(ScheduleHearingTask).to receive(:create!).and_raise(StandardError)
        expect(Rails.logger).to receive(:error).at_least(:once)
        subject.perform
      end
    end

    context "Batch limit environment variable set to 500" do
      before do
        Hearings::TravelBoardHearingSyncJob::BATCH_LIMIT = "500"
      end

      it "limit paramter should be 500 when fetching" do
        expect(subject).to receive(:fetch_vacols_travel_board_appeals).with(500)
        subject.perform
      end
    end
  end
end
