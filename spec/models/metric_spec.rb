# frozen_string_literal: true

describe Metric do
  let(:user) { create(:user) }

  before { User.authenticate!(user: user) }

  describe "create_metric" do
    let!(:params) do
      {
        uuid: SecureRandom.uuid,
        method: "123456789",
        name: "log",
        group: "service",
        message: "This is a test",
        type: "performance",
<<<<<<< HEAD
        product: "reader"
      }
=======
        product: "reader",
        sent_to: "rails_console"
       }
>>>>>>> b9a6332b0 (metric and spec file updated)
    end

    it "creates a javascript metric for performance" do
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:performance])
    end

    it "creates a javascript metric for log" do
      params[:type] = "log"
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:log])
    end

    it "user created if no user logged in" do
      metric = Metric.create_metric(self, params, nil)

      expect(metric.user).to be_present
    end

    it "creates a javascript metric for error" do
<<<<<<< HEAD
      params[:type] = "error"
=======
      params[:type]  = "error"
>>>>>>> b9a6332b0 (metric and spec file updated)
      metric = Metric.create_metric(self, params, user)

      expect(metric.valid?).to be true
      expect(metric.metric_type).to eq(Metric::METRIC_TYPES[:error])
    end

    it "creates a javascript metric with invalid sent_to" do
<<<<<<< HEAD
      metric = Metric.create_metric(self, params.merge(sent_to: "fake"), user)
=======
      metric = Metric.create_metric(self, params.merge({sent_to: "fake"}), user)
>>>>>>> b9a6332b0 (metric and spec file updated)

      expect(metric.valid?).to be false
    end
  end
end
