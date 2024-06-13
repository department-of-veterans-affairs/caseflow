# frozen_string_literal: true

describe Api::Docs::V3::DocsController do
  let(:spec) do
    YAML.safe_load(File.read(File.join(Rails.root, "app/controllers/swagger/v3/decision_reviews.yaml")))
  end

  describe "#decision_reviews" do
    it "exists and is valid yaml" do
      expect { spec }.not_to raise_error
    end

    describe "/higher_level_reviews documentation" do

      let(:hlr_doc) do
        json = JSON.parse(spec.body)
        json["paths"]["/higher_level_reviews"]
      end
      it "should have POST" do
        expect(hlr_doc).to include("post")
      end
    end
    describe "/intake_statuses/{uuid} documentation" do
      let(:hlr_intake_status_doc) do
        json = JSON.parse(spec.body)
        json["paths"]["/intake_statuses/{uuid}"]
      end
      it "should have GET" do
        expect(hlr_intake_status_doc).to include("get")
      end
    end
    describe "/higher_level_reviews/{uuid} documentation" do
      let(:hlr_intake_status_doc) do
        json = JSON.parse(spec.body)
        json["paths"]["/higher_level_reviews/{uuid}"]
      end
      it "should have GET" do
        expect(hlr_intake_status_doc).to include("get")
      end
    end
  end
end
