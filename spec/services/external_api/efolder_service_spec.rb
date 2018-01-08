require "rails_helper"
require "faker"

describe ExternalApi::EfolderService do
  let(:base_url) { Faker::Internet.url }
  let(:efolder_key) { Faker::Internet.device_token }

  context "#efolder_base_url" do
    subject { ExternalApi::EfolderService.efolder_base_url }
    it "retrieves the efolder_url value from Rails configuration" do
      Rails.application.config.efolder_url = base_url
      expect(subject).to eq(base_url)
    end

    it "returns empty string if Rails.application.config.efolder_url is not set" do
      Rails.application.config.efolder_url = nil
      expect(subject).to eq("")
    end
  end

  context "#efolder_key" do
    subject { ExternalApi::EfolderService.efolder_key }

    it "retrieves the efolder_key value from Rails configuration" do
      Rails.application.config.efolder_key = efolder_key
      expect(subject).to eq(efolder_key)
    end

    it "returns empty string if Rails.application.config.efolder_key is not set" do
      Rails.application.config.efolder_key = nil
      expect(subject).to eq("")
    end
  end

  context "#fetch_documents_for" do
    let(:user) { Generators::User.build }
    let(:appeal) { Generators::Appeal.build }

    context "when efolder v2 is not enabled" do
      subject { ExternalApi::EfolderService.fetch_documents_for(appeal, user) }

      it "it uses efolder v1 api" do
        expect(ExternalApi::EfolderService).to receive(:efolder_v1_api)
        subject
      end
    end

    context "when efolder v2 is enabled" do
      before do
        FeatureToggle.enable!(:efolder_api_v2, users: [user.css_id])
      end

      after do
        FeatureToggle.disable!(:efolder_api_v2, users: [user.css_id])
      end

      subject { ExternalApi::EfolderService.fetch_documents_for(appeal, user) }

      it "it uses efolder v2 api" do
        expect(ExternalApi::EfolderService).to receive(:efolder_v2_api)
        subject
      end
    end
  end

  context "#efolder_v2_api" do
    let(:user) { Generators::User.build }
    let(:appeal) { Generators::Appeal.build }
    let(:vbms_id) { appeal.sanitized_vbms_id.to_s }
    let(:manifest_vbms_fetched_at) { Time.zone.now.strftime("%D %l:%M%P %Z") }
    let(:manifest_vva_fetched_at) { Time.zone.now.strftime("%D %l:%M%P %Z") }
    let(:expected_response) { construct_response(records, sources) }

    subject { ExternalApi::EfolderService.efolder_v2_api(vbms_id, user) }

    context "metrics" do
      let(:sources) do
        [
          {
            source: "VVA",
            status: "failed",
            fetched_at: nil
          },
          {
            source: "VBMS",
            status: "failed",
            fetched_at: nil
          }
        ]
      end

      let(:records) { [] }

      it "are recorded using MetricsService" do
        # We trigger a load of vacols data, before writing our expect statement for MetricsService to receive :record
        # since loading vacols data is also wrapped through MetricsService, and we don't want that call to also
        # return the expected_response.
        appeal.check_and_load_vacols_data!
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        expect(MetricsService).to receive(:record).with(/eFolder/, any_args).and_return(expected_response).once
        subject
      end
    end

    context "invalid url argument" do
      it "throws ArgumentError" do
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(Faker::ChuckNorris.fact).once
        expect(HTTPI).not_to receive(:get)
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "returns HTTP response" do
      before do
        allow(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url)
        allow(ExternalApi::EfolderService).to receive(:efolder_key).and_return(efolder_key)
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(expected_response)
      end

      context "when both sources come back as successful" do
        let(:records) do
          [
            {
              id: "1",
              type_id: "97",
              external_document_id: expected_document1.vbms_document_id,
              received_at: expected_received_at1
            },
            {
              id: "2",
              type_id: "73",
              external_document_id: expected_document2.vbms_document_id,
              received_at: expected_received_at2
            }
          ]
        end

        let(:sources) do
          [
            {
              source: "VVA",
              status: "success",
              fetched_at: manifest_vva_fetched_at
            },
            {
              source: "VBMS",
              status: "success",
              fetched_at: manifest_vbms_fetched_at
            }
          ]
        end

        let(:expected_result) do
          {
            documents: [expected_document1.to_hash, expected_document2.to_hash],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end

        let(:expected_received_at1) { Faker::Date.backward }
        let(:expected_received_at2) { Faker::Date.backward }
        let(:expected_document1) do
          Generators::Document.build(type: "SSOC", filename: nil, file_number: appeal.sanitized_vbms_id)
        end
        let(:expected_document2) do
          Generators::Document.build(type: "NOD", filename: nil, file_number: appeal.sanitized_vbms_id)
        end

        it "returns an array with all Document objects" do
          expected_document1.received_at = expected_received_at1.to_s
          expected_document2.received_at = expected_received_at2.to_s
          subject[:documents] = subject[:documents].map(&:to_hash)
          expect(subject).to eq(expected_result)
        end
      end

      context "when both sources come back as pending and then success" do
        let(:records1) { [] }
        let(:sources1) do
          [
            {
              source: "VVA",
              status: "pending",
              fetched_at: nil
            },
            {
              source: "VBMS",
              status: "pending",
              fetched_at: manifest_vbms_fetched_at
            }
          ]
        end

        let(:records2) do
          [
            {
              id: "1",
              type_id: "97",
              external_document_id: expected_document1.vbms_document_id,
              received_at: expected_received_at1
            }
          ]
        end
        let(:sources2) do
          [
            {
              source: "VVA",
              status: "success",
              fetched_at: manifest_vva_fetched_at
            },
            {
              source: "VBMS",
              status: "success",
              fetched_at: manifest_vbms_fetched_at
            }
          ]
        end

        let(:expected_response) { construct_response(records1, sources1) }
        let(:expected_response2) { construct_response(records2, sources2) }

        let(:expected_result) do
          {
            documents: [expected_document1.to_hash],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end

        let(:expected_received_at1) { Faker::Date.backward }

        let(:expected_document1) do
          Generators::Document.build(type: "SSOC", filename: nil, file_number: appeal.sanitized_vbms_id)
        end

        it "should make another request if pending status" do
          expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request))
            .and_return(expected_response, expected_response2)
          expected_document1.received_at = expected_received_at1.to_s
          subject[:documents] = subject[:documents].map(&:to_hash)
          expect(subject).to eq(expected_result)
        end
      end

      context "when HTTP error" do
        let(:expected_response) { HTTPI::Response.new(404, [], {}) }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { ExternalApi::EfolderService.efolder_v1_api(vbms_id, user) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end

      context "when sources are not available" do
        let(:records) { [] }
        let(:sources) { [] }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { subject }.to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end

      context "when all sources come back as failed" do
        let(:sources) do
          [
            {
              source: "VVA",
              status: "failed",
              fetched_at: nil
            },
            {
              source: "VBMS",
              status: "failed",
              fetched_at: nil
            }
          ]
        end
        let(:records) { [] }

        let(:expected_result) do
          {
            documents: [],
            manifest_vbms_fetched_at: nil,
            manifest_vva_fetched_at: nil
          }
        end

        it { is_expected.to eq expected_result }
      end

      context "when one source comes back as failed" do
        let(:sources) do
          [
            {
              source: "VVA",
              status: "success",
              fetched_at: manifest_vva_fetched_at
            },
            {
              source: "VBMS",
              status: "failed",
              fetched_at: nil
            }
          ]
        end
        let(:records) { [] }

        let(:expected_result) do
          {
            documents: [],
            manifest_vbms_fetched_at: nil,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end

        it { is_expected.to eq expected_result }
      end
    end
  end

  context "#efolder_v1_api" do
    let(:user) { Generators::User.build }
    let(:appeal) { Generators::Appeal.build }
    let(:vbms_id) { appeal.sanitized_vbms_id.to_s }
    let(:expected_response) { HTTPI::Response.new(200, [], expected_response_map.to_json) }
    let(:manifest_vbms_fetched_at) { Time.zone.now.strftime("%D %l:%M%P %Z") }
    let(:manifest_vva_fetched_at) { Time.zone.now.strftime("%D %l:%M%P %Z") }

    context "metrics" do
      let(:expected_response_map) { { data: { attributes: { documents: nil } } } }

      it "are recorded using MetricsService" do
        # We trigger a load of vacols data, before writing our expect statement for MetricsService to receive :record
        # since loading vacols data is also wrapped through MetricsService, and we don't want that call to also
        # return the expected_response.
        appeal.check_and_load_vacols_data!
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        expect(MetricsService).to receive(:record).with(/eFolder/, any_args).and_return(expected_response).once
        ExternalApi::EfolderService.efolder_v1_api(vbms_id, user)
      end
    end

    context "invalid url argument" do
      it "throws ArgumentError" do
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(Faker::ChuckNorris.fact).once
        expect(HTTPI).not_to receive(:get)
        expect { ExternalApi::EfolderService.efolder_v1_api(vbms_id, user) }.to raise_error(ArgumentError)
      end
    end

    context "eFolder returns HTTP response" do
      let(:expected_response_map) { { data: { attributes: attrs_in } } }

      before do
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        expect(ExternalApi::EfolderService).to receive(:efolder_key).and_return(efolder_key).once
        expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(expected_response).once
      end

      context "with null documents field" do
        let(:expected_result) { { documents: [], manifest_vbms_fetched_at: nil, manifest_vva_fetched_at: nil } }
        let(:attrs_in) { { documents: nil, manifest_vbms_fetched_at: nil, manifest_vva_fetched_at: nil } }

        it "returns empty array for documents and null fetched_at fields" do
          expect(ExternalApi::EfolderService.efolder_v1_api(vbms_id, user)).to eq(expected_result)
        end
      end

      context "with empty documents array field and null fetched_at fields" do
        let(:expected_result) { { documents: [], manifest_vbms_fetched_at: nil, manifest_vva_fetched_at: nil } }
        let(:attrs_in) { expected_result }

        it "returns empty array for documents and null fetched_at fields" do
          expect(ExternalApi::EfolderService.efolder_v1_api(vbms_id, user)).to eq(expected_result)
        end
      end

      context "with one document" do
        let(:expected_received_at1) { Faker::Date.backward }
        let(:expected_document1) do
          Generators::Document.build(type: "SSOC", filename: nil, file_number: appeal.sanitized_vbms_id)
        end
        let(:attrs_in) do
          {
            documents: [
              {
                id: "1",
                type_id: "97",
                external_document_id: expected_document1.vbms_document_id,
                received_at: expected_received_at1
              }
            ],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end
        let(:expected_result) do
          {
            documents: [expected_document1.to_hash],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end

        it "returns an array with the document" do
          # Convert the received_at to a string so we can compare the results properly
          expected_document1.received_at = expected_received_at1.to_s

          # Use to_hash to do a deep comparison and ensure all properties were deserialized correctly
          result = ExternalApi::EfolderService.efolder_v1_api(vbms_id, user)
          result[:documents] = result[:documents].map(&:to_hash)

          expect(result).to eq(expected_result)
        end
      end

      context "with multiple documents" do
        let(:attrs_in) do
          {
            documents: [
              {
                id: "1",
                type_id: "97",
                external_document_id: expected_document1.vbms_document_id,
                received_at: expected_received_at1
              },
              {
                id: "2",
                type_id: "73",
                external_document_id: expected_document2.vbms_document_id,
                received_at: expected_received_at2
              }
            ],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end
        let(:expected_result) do
          {
            documents: [expected_document1.to_hash, expected_document2.to_hash],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end

        let(:expected_received_at1) { Faker::Date.backward }
        let(:expected_received_at2) { Faker::Date.backward }
        let(:expected_document1) do
          Generators::Document.build(type: "SSOC", filename: nil, file_number: appeal.sanitized_vbms_id)
        end
        let(:expected_document2) do
          Generators::Document.build(type: "NOD", filename: nil, file_number: appeal.sanitized_vbms_id)
        end

        it "returns an array with all Document objects" do
          # Convert the received_at to a string so we can compare the results properly
          expected_document1.received_at = expected_received_at1.to_s
          expected_document2.received_at = expected_received_at2.to_s

          # Use to_hash to do a deep comparison and ensure all properties were deserialized correctly
          result = ExternalApi::EfolderService.efolder_v1_api(vbms_id, user)
          result[:documents] = result[:documents].map(&:to_hash)

          expect(result).to eq(expected_result)
        end
      end

      context "with error code" do
        let(:expected_response) { HTTPI::Response.new(404, [], {}) }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { ExternalApi::EfolderService.efolder_v1_api(vbms_id, user) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end
    end

    context "when efolder returns an error403 HTTP response" do
      let(:http_resp_403) { HTTPI::Response.new(403, [], { status: "forbidden: sensitive record" }) }
      it "raises EfolderAccessForbidden exception given a 403 HTTP response" do
        allow(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        allow(HTTPI).to receive(:get).and_return(http_resp_403).once
        expect { ExternalApi::EfolderService.efolder_v1_api(vbms_id, user) }.to raise_error(Caseflow::Error::EfolderAccessForbidden)
      end

      let(:http_resp_400) { HTTPI::Response.new(400, [], { status: "bad request" }) }
      it "raises DocumentRetrievalError exception given a 400 HTTP response" do
        allow(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        allow(HTTPI).to receive(:get).and_return(http_resp_400).once
        expect { ExternalApi::EfolderService.efolder_v1_api(vbms_id, user) }.to raise_error(Caseflow::Error::DocumentRetrievalError)
      end
    end
  end

  def construct_response(records, sources)
    response = { data: { attributes: { records: records, sources: sources } } }
    HTTPI::Response.new(200, [], response.to_json)
  end
end
