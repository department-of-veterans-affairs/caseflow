require 'rails_helper'

RSpec.describe "SplitAppeals", type: :request do

  describe "GET /split" do
    it "returns http success" do
      get "/split_appeal/split"
      expect(response).to have_http_status(:success)
    end
  end

end
