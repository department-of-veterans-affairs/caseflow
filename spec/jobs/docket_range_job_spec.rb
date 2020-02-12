# frozen_string_literal: true

require "faker"

describe DocketRangeJob, :postgres do
  describe "#perform" do
    let(:today) { Time.zone.now }
    let(:docket_coord) { DocketCoordinator.new }
    before do
      30.times do |index|
        create(:appeal,
               :with_post_intake_tasks,
               docket_range_date: (index < 16) ? nil : Time.utc(today.year, today.month, 1))
      end

      allow(DocketCoordinator).to receive(:new)
        .and_return(docket_coord)

      allow(docket_coord).to receive(:target_number_of_ama_hearings)
        .and_return(15)

      allow(docket_coord.dockets[:hearing]).to receive(:appeals)
        .and_return(Appeal.all)
    end

    it "adds docket_range_date to last 15 appeals" do
      DocketRangeJob.perform_now
      expected_date = (today + 1.month).end_of_month
      appeals = Appeal.where(docket_range_date: expected_date)
      expect(appeals.count).to eq(15)
    end
  end
end
