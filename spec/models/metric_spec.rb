# frozen_string_literal: true

describe Metric do
  let(:user) { create(:user) }

  before { User.authenticate!(user: user) }

  describe "create_metric" do
    let!(:params) do
       {
        uuid: SecureRandom.uuid,
        method: "123456789",
        name: 'log',
        group: 'service',
        message: 'This is a test',
        type: 'performance',
        product: 'reader',
       }
    end

    it "creates a javascript metric for performance" do
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:performance])
    end

    it "creates a javascript metric for log" do
      params[:type] = 'log'
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:log])
    end

    it "creates a javascript metric for error" do
      params[:type]  = 'error'
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:error])
    end

    it "creates a javascript metric with invalid sent_to" do
      metric = Metric.create_metric(self, params.merge({sent_to: 'fake'}), user)

      expect(metric.valid?).to be false
    end
  end
end
