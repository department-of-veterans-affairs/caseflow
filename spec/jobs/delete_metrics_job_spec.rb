# frozen_string_literal: true

RSpec.describe DeleteMetricsJob, type: :job do
  let(:metric_type) {  Metric::METRIC_TYPES[:performance] }
  let(:metric_product) { Metric::PRODUCT_TYPES[:reader] }
  let(:metric_message) { "metric_message" }
  let(:months) { 3 }
  let(:user) { create(:default_user) }
  let(:query_options) do
    {
      metric_type: metric_type,
      metric_product: metric_product,
      metric_message: metric_message,
      months: months
    }
  end
  let(:job) { DeleteMetricsJob.new(query_options) }

  def create_four_month_old_metrics
    @four_month_old_metrics =
      create_list(:metric,
                  5,
                  metric_type: metric_type,
                  created_at: 4.months.ago,
                  metric_product: metric_product,
                  user: user)
  end

  def create_one_month_old_metrics
    @one_month_old_metrics =
      create_list(:metric,
                  3, metric_type: metric_type,
                     created_at: 1.month.ago,
                     metric_product: metric_product,
                     user: user)
  end

  describe "#perform" do
    context "when options are not included" do
      let(:job) { DeleteMetricsJob.new({}) }

      it "does not perform any deletion" do
        expect(Metric).not_to receive(:where)
        job.perform
      end
    end

    context "when metric_type options is included" do
      let(:job2) do
        DeleteMetricsJob.new({
                               metric_type: Metric::METRIC_TYPES.except(:performance).values.sample,
                               metric_product: metric_product,
                               months: 5
                             })
      end

      it "deletes metrics matching the query in batches" do
        create_four_month_old_metrics
        allow(Metric).to receive(:where).and_call_original
        expect { job.perform }.to change { Metric.count }.by(-5)
      end

      it "does not delete any metrics if none match the query" do
        create_four_month_old_metrics
        expect { job2.perform }.to change { Metric.count }.by(0)
      end
    end
  end

  describe "#perform_dry_run" do
    context "when options are not included" do
      let(:job) { DeleteMetricsJob.new({}) }

      it "does not perform any operation and returns nil" do
        expect(job.perform_dry_run).to be_nil
      end
    end

    context "when options are included" do
      it "returns the count of records that would be deleted" do
        create_four_month_old_metrics

        result = job.perform_dry_run
        expect(result).to eq("Dry Run: 5 records would be deleted.")
      end

      it "returns 0 if no records match the query" do
        create_one_month_old_metrics

        result = job.perform_dry_run
        expect(result).to eq("Dry Run: 0 records would be deleted.")
      end
    end
  end

  describe "#get_metric_ids" do
    it "returns IDs of metrics matching the query" do
      create_four_month_old_metrics
      expect(job.send(:get_metric_ids)).to match_array(@four_month_old_metrics.map(&:id))
    end

    it "returns an empty array if no metrics match the query" do
      create_one_month_old_metrics
      expect(job.send(:get_metric_ids)).to eq([])
    end
  end

  describe "#destroy_in_batches" do
    it "deletes records in batches of the specified size" do
      create_list(
        :metric, 1500,
        metric_type: metric_type,
        created_at: 4.months.ago,
        metric_product: metric_product,
        user: user
      )
      expect { job.perform }.to change { Metric.count }.by(-1500)
    end
  end
end
