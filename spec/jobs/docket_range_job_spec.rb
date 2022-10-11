# frozen_string_literal: true

describe DocketRangeJob do
  describe "#perform" do
    let(:today) { Time.zone.now }
    let(:docket_coord) { DocketCoordinator.new }
    let(:appeals_with_nil_docket_range_date) { 16 }
    let(:target_number_of_appeals) { 15 }

    before(:all) do
      Seeds::NotificationEvents.new.seed!
    end

    before do
      docket_range_date = Time.utc(today.year, today.month, 1)

      30.times do |index|
        create(
          :appeal,
          :with_post_intake_tasks,
          docket_range_date: (index < appeals_with_nil_docket_range_date) ? nil : docket_range_date
        )
      end

      allow(DocketCoordinator).to receive(:new)
        .and_return(docket_coord)

      allow(docket_coord).to receive(:target_number_of_ama_hearings)
        .and_return(target_number_of_appeals)

      allow(docket_coord.dockets[:hearing]).to receive(:appeals)
        .and_return(Appeal.all)
    end

    it "adds docket_range_date to last 15 appeals" do
      DocketRangeJob.perform_now

      appeals = Appeal.where(docket_range_date: DocketRangeJob.end_of_time_period)
      expect(appeals.count).to eq(target_number_of_appeals)
    end

    it "results do not change when job is run multiple times" do
      DocketRangeJob.perform_now
      DocketRangeJob.perform_now
      DocketRangeJob.perform_now

      appeals = Appeal.where(docket_range_date: DocketRangeJob.end_of_time_period)
      expect(appeals.count).to eq(target_number_of_appeals)
    end

    it "covers untouched appeals in next month" do
      DocketRangeJob.perform_now

      expect(
        Appeal
          .where(docket_range_date: DocketRangeJob.end_of_time_period)
          .count
      ).to eq(target_number_of_appeals)

      # Ensure if job starts next month, it will modify a different set of appeals
      Timecop.freeze((today + 1.month).beginning_of_month) do
        DocketRangeJob.perform_now

        expect(
          Appeal
            .where(docket_range_date: DocketRangeJob.end_of_time_period)
            .count
        ).to eq(appeals_with_nil_docket_range_date - target_number_of_appeals)
      end

      # Ensure all appeals have docket_range_job field populated
      expect(
        Appeal.where.not(docket_range_date: nil).count
      ).to eq(30)
    end
  end
end
