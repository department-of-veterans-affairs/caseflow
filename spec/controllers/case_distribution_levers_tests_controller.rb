# frozen_string_literal: true

describe CaseDistributionLeversTestsController do
  before do
    Timecop.freeze(Time.utc(2024, 1, 1, 12, 0, 0))
    User.authenticate!(user: User.system_user)
  end

  context "#appeals_ready_to_distribute" do
    it "downloads a properly named CSV file" do
      get :appeals_ready_to_distribute, format: :csv

      expect(response.headers["Content-Type"]).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("appeals_ready_to_distribute_20240101-0700.csv")
    end
  end

  context "#appeals_distributed" do
    it "downloads a properly named CSV file" do
      get :appeals_distributed, format: :csv

      expect(response.headers["Content-Type"]).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("distributed_appeals_20240101-0700.csv")
    end
  end
end
