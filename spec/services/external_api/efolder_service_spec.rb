require "rails_helper"
require "faker"

describe ExternalApi::EfolderService do
  let(:base_url) { Faker::Internet.url }
  let(:efolder_key) { Faker::Internet.device_token }

  context "#efolder_base_url" do
    it "retrieves the efolder_url value from Rails configuration" do
      Rails.application.config.efolder_url = base_url
      expect(ExternalApi::EfolderService.efolder_base_url).to eq(base_url)
    end

    it "returns empty string if Rails.application.config.efolder_url is not set" do
      Rails.application.config.efolder_url = nil
      expect(ExternalApi::EfolderService.efolder_base_url).to eq("")
    end
  end

  context "#efolder_key" do
    it "retrieves the efolder_key value from Rails configuration" do
      Rails.application.config.efolder_key = efolder_key
      expect(ExternalApi::EfolderService.efolder_key).to eq(efolder_key)
    end

    it "returns empty string if Rails.application.config.efolder_key is not set" do
      Rails.application.config.efolder_key = nil
      expect(ExternalApi::EfolderService.efolder_key).to eq("")
    end
  end

  context "#fetch_documents_for" do
    let(:user) { Generators::User.build }
    let(:appeal) { Generators::Appeal.build }
    let(:expected_response) { HTTPI::Response.new(200, [], expected_response_map.to_json) }
    let(:manifest_vbms_fetched_at) { Time.now.strftime('%D %l:%M%P %Z') }
    let(:manifest_vva_fetched_at) { Time.now.strftime('%D %l:%M%P %Z') }

    context "metrics" do
      let(:expected_response_map) { { data: { attributes: { documents: nil } } } }

      it "are recorded using MetricsService" do
        # We trigger a load of vacols data, before writing our expect statement for MetricsService to receive :record
        # since loading vacols data is also wrapped through MetricsService, and we don't want that call to also
        # return the expected_response.
        appeal.check_and_load_vacols_data!
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        expect(MetricsService).to receive(:record).with(/eFolder/, any_args).and_return(expected_response).once
        ExternalApi::EfolderService.fetch_documents_for(appeal, user)
      end
    end

    context "invalid url argument" do
      it "throws ArgumentError" do
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(Faker::ChuckNorris.fact).once
        expect(HTTPI).not_to receive(:get)
        expect { ExternalApi::EfolderService.fetch_documents_for(appeal, user) }.to raise_error(ArgumentError)
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
          expect(ExternalApi::EfolderService.fetch_documents_for(appeal, user)).to eq(expected_result)
        end
      end

      context "with empty documents array field and null fetched_at fields" do
        let(:expected_result) { { documents: [], manifest_vbms_fetched_at: nil, manifest_vva_fetched_at: nil } }
        let(:attrs_in) { expected_result }

        it "returns empty array for documents and null fetched_at fields" do
          expect(ExternalApi::EfolderService.fetch_documents_for(appeal, user)).to eq(expected_result)
        end
      end

      context "with one document" do
        let(:expected_received_at1) { Faker::Date.backward }
        let(:expected_document1) { Generators::Document.build( type: "SSOC", filename: nil ) }
        let(:attrs_in) do
          {
            documents: [
              {
                id: "1",
                type_id: "97",
                external_document_id: expected_document1.vbms_document_id,
                received_at: expected_received_at1
              }],
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
          result = ExternalApi::EfolderService.fetch_documents_for(appeal, user)
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
        let(:expected_document1) { Generators::Document.build(type: "SSOC", filename: nil) }
        let(:expected_document2) { Generators::Document.build(type: "NOD", filename: nil) }

        it "returns an array with all Document objects" do
          # Convert the received_at to a string so we can compare the results properly
          expected_document1.received_at = expected_received_at1.to_s
          expected_document2.received_at = expected_received_at2.to_s

          # Use to_hash to do a deep comparison and ensure all properties were deserialized correctly
          result = ExternalApi::EfolderService.fetch_documents_for(appeal, user)
          result[:documents] = result[:documents].map(&:to_hash)

          expect(result).to eq(expected_result)
        end
      end

      context "with error code" do
        let(:expected_response) { HTTPI::Response.new(404, [], {}) }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { ExternalApi::EfolderService.fetch_documents_for(appeal, user) }
            .to raise_error(Caseflow::Error::DocumentRetrievalError)
        end
      end
    end
  end
end
