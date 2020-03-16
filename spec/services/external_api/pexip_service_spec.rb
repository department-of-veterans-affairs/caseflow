# frozen_string_literal: true

describe ExternalApi::PexipService do
  let(:pexip_service) do
    ExternalApi::PexipService.new(
      host: "vapnnevnpmn.care.va.gov",
      user_name: "pexip",
      password: "1234",
      client_host: "care.va.gov"
    )
  end

  let(:endpoint) { "api/admin/configuration/v1/conference/" }

  describe "#create_conference" do
    let(:body) do
      {
        "aliases": [{ "alias": "1111111" }, { "alias": "BVA1111111" }, { "alias": "BVA1111111.care.va.gov" }],
        "allow_guests": true,
        "description": "Created by Caseflow",
        "enable_chat": "yes",
        "enable_overlay_text": true,
        "force_presenter_into_main": true,
        "ivr_theme": "/api/admin/configuration/v1/ivr_theme/2/",
        "guest_pin": "5678",
        "name": "BVA1111111",
        "pin": "1234",
        "tag": "CASEFLOW"
      }
    end

    subject { pexip_service.create_conference(host_pin: 1234, guest_pin: 5678, name: "1111111") }

    let(:success_create_resp) do
      HTTPI::Response.new(201, { "Location" => "api/admin/configuration/v1/conference/1234" }, {})
    end

    let(:error_create_resp) do
      HTTPI::Response.new(
        400,
        {},
        { "conference" => { "name" => ["Virtual room for this name already exist."] } }.to_json
      )
    end

    it "calls #send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request)
      subject
    end

    it "passed correct arguments to #send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request).with(endpoint, :post, body: body)
      subject
    end

    it "returns an instance of ExternalApi::PexipService::CreateResponse class" do
      allow(pexip_service).to receive(:send_pexip_request).with(endpoint, :post, body: body)
        .and_return(success_create_resp)

      expect(subject).to be_instance_of(ExternalApi::PexipService::CreateResponse)
    end

    it "success response" do
      allow(pexip_service).to receive(:send_pexip_request).with(endpoint, :post, body: body)
        .and_return(success_create_resp)

      expect(subject.code).to eq(201)
      expect(subject.success?).to eq(true)
      expect(subject.data).to eq("conference_id": "1234")
    end

    it "error response" do
      allow(pexip_service).to receive(:send_pexip_request).with(endpoint, :post, body: body)
        .and_return(error_create_resp)

      expect(subject.code).to eq(400)
      expect(subject.success?).to eq(false)
      expect(subject.error).to eq(
        Caseflow::Error::PexipBadRequestError.new(code: 400, message: "Virtual room for this name already exist.")
      )
    end
  end

  describe "#delete_conference" do
    subject { pexip_service.delete_conference(conference_id: "123") }

    let(:success_del_resp) { HTTPI::Response.new(204, {}, {}) }
    let(:error_del_resp) { HTTPI::Response.new(404, {}, {}) }

    it "calls #send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request)
      subject
    end

    it "passed correct arguments to #send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request).with("#{endpoint}123/", :delete)
      subject
    end

    it "success response" do
      allow(pexip_service).to receive(:send_pexip_request).with("#{endpoint}123/", :delete)
        .and_return(success_del_resp)

      expect(subject.code).to eq(204)
      expect(subject.success?).to eq(true)
      expect(subject.data).to eq(nil)
    end

    it "error response" do
      allow(pexip_service).to receive(:send_pexip_request).with("#{endpoint}123/", :delete)
        .and_return(error_del_resp)

      expect(subject.code).to eq(404)
      expect(subject.success?).to eq(false)
      expect(subject.error).to eq(Caseflow::Error::PexipNotFoundError.new(code: 404, message: "No error message"))
    end
  end
end
