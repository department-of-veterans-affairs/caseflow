# frozen_string_literal: true

describe Metric do
  let(:user) { create(:user) }

  describe "create_javascript_metric" do
    let!(:params) do
       {
        method: "123456789",
        uuid: "PAT123456^CFL200^A",
        url: '',
        message: '',
        isError: false,
        isPerformance: false,
        source: 'javascript'
       }
    end

    it "creates a javascript metric for log" do
      options = {is_error: false, performance: false}
      metric = Metric.create_javascript_metric(params, user, options)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:log])
    end

    it "creates a javascript metric for error" do
      options = {is_error: true, performance: false}
      metric = Metric.create_javascript_metric(params, user, options)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:error])
    end

    it "creates a javascript metric for performance" do
      options = {is_error: false, performance: true}
      metric = Metric.create_javascript_metric(params, user, options)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:performance])
    end

    it "creates a javascript metric with invalid sent_to" do
      options = {is_error: false, performance: false}
      metric = Metric.create_javascript_metric(params.merge({sent_to: 'fake'}), user, options)

      expect(metric.valid?).to be false
    end
  end
end
