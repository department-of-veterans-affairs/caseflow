# frozen_string_literal: true

describe Api::V1::MpiController, type: :controller do
  let(:api_key) { ApiKey.create!(consumer_name: "API Consumer").key_string }
  let(:request_params) do
    {
      veterans_ssn: "123456789",
      veterans_pat: "PAT123456^CFL200^A",
      deceased_time: 1.day.ago
    }
  end

  let(:updated_vet) do
    create(:correspondent,
           stafkey: request_params[:veterans_pat].split("^")[0],
           ssn: request_params[:veterans_ssn],
           sfnod: request_params[:deceased_time])
  end

  context "authorization" do
    it "fails if user provides no API key" do
      post :veteran_updates, params: request_params
      expect(response.status).to eq(401)
    end

    it "fails if user provides a bad API key" do
      request.headers["Authorization"] = "bad_api_key"
      post :veteran_updates, params: request_params
      expect(response.status).to eq(401)
    end
  end

  context "an error occurs" do
    it "updates the MpiUpdatePersonEvent and raises the error" do
      allow(VACOLS::Correspondent).to receive(:update_veteran_nod).and_raise(StandardError)

      request.headers["Authorization"] = "Bearer #{api_key}"
      post :veteran_updates, params: request_params

      mpi_update_event = MpiUpdatePersonEvent.last
      expect(mpi_update_event.update_type).to eq("error")
      expect(response.status).to eq(500)
    end
  end

  context "with good request" do
    it "returns 200 and calls update_veteran_nod" do
      expect(VACOLS::Correspondent).to receive(:update_veteran_nod).and_return("successful")
      expect(VACOLS::Correspondent).to receive(:find_by).and_return(updated_vet)
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :veteran_updates, params: request_params

      mpi_update_event = MpiUpdatePersonEvent.last
      expect(mpi_update_event.update_type).to eq("successful")
      expect(mpi_update_event.info["updated_column"]).to eq("deceased_time")
      expect(mpi_update_event.info["updated_deceased_time"].to_date).to eq(request_params[:deceased_time].to_date)
      expect(response.status).to eq(200)
    end
  end
end
