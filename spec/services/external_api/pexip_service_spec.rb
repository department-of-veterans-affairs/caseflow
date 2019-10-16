# frozen_string_literal: true

describe ExternalApi::PexipService, focus: true do
  let(:pexip_service) do
    ExternalApi::PexipService.new(
      host: "vapnnevnpmn.care.va.gov",
      user_name: "pexip",
      password: "1234",
      client_host: "care.va.gov"
    )
  end

  describe "#create_conference" do
    let(:body) do
      {
        "aliases": [{ "alias": "1111111" }, { "alias": "BVA1111111" }, { "alias": "BVA1111111.care.va.gov" }],
        "allow_guests": true,
        "description": "Created by Caseflow",
        "enable_chat": "yes",
        "enable_overlay_text": true,
        "force_presenter_into_main": true,
        "guest_pin": "5678",
        "name": "BVA1111111",
        "pin": "1234",
        "tag": "CASEFLOW"
      }
    end

    it "calls #send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request)
      pexip_service.create_conference(1234, 5678, 1111111)
    end

    it "passed correct arguments to send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request).with("api/admin/configuration/v1/conference/", :post, body: body)
      pexip_service.create_conference(1234, 5678, 1111111)
    end
  end

  describe "#delete_conference" do
    it "calls send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request)
      pexip_service.delete_conference(123)
    end

    it "passed correct arguments to send_pexip_request" do
      expect(pexip_service).to receive(:send_pexip_request).with("api/admin/configuration/v1/conference/123/", :delete)
      pexip_service.delete_conference(123)
    end
  end
end
