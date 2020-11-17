# frozen_string_literal: true

require "faker"

describe ExternalApi::EfolderService, :postgres do
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

  context "#fetch_document_count" do
    let(:user) { Generators::User.create }
    let(:file_number) { "1234" }
    let(:expected_response) { HTTPI::Response.new(200, [], { documents: "20" }.to_json) }
    let(:cache_key) { "Efolder-document-count-#{file_number}" }

    before do
      allow(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url)
      allow(ExternalApi::EfolderService).to receive(:efolder_key).and_return(efolder_key)
      allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(expected_response)
    end

    subject { ExternalApi::EfolderService.fetch_document_count(file_number, user) }

    it "returns document count" do
      expect(subject).to eq("20")
    end

    it "caches result" do
      expect(Rails.cache.exist?(cache_key)).to eq(false)
      subject
      expect(Rails.cache.exist?(cache_key)).to eq(true)
    end
  end

  context "#document_count" do
    let(:user) { Generators::User.create }
    let(:file_number) { "1234" }
    let(:cache_key) { "Efolder-document-count-#{file_number}" }
    let(:job_cache_key) { "Efolder-document-count-bgjob-#{file_number}" }

    subject { ExternalApi::EfolderService.document_count(file_number, user) }

    before do
      allow(FetchEfolderDocumentCountJob).to receive(:perform_later) { true }
    end

    context "doc count is already cached" do
      before do
        Rails.cache.write(cache_key, 10)
      end

      it "returns cached value" do
        expect(subject).to eq(10)
      end
    end

    context "doc count is not yet cached" do
      it "creates background job, once" do
        expect(Rails.cache.exist?(cache_key)).to eq(false)
        expect(Rails.cache.exist?(job_cache_key)).to eq(false)
        subject
        expect(Rails.cache.exist?(cache_key)).to eq(false)
        expect(Rails.cache.exist?(job_cache_key)).to eq(true)
        subject # call again to test sentinel cache key
        expect(FetchEfolderDocumentCountJob).to have_received(:perform_later).once
      end
    end
  end

  context "#generate_efolder_request" do
    let(:user) { Generators::User.create }
    let(:appeal) { Generators::LegacyAppeal.build }
    let(:vbms_id) { appeal.sanitized_vbms_id.to_s }
    let(:fetched_at_format) { "%D %l:%M%P %Z %z" }
    let(:manifest_vbms_fetched_at) { Time.zone.now.strftime(fetched_at_format) }
    let(:manifest_vva_fetched_at) { Time.zone.now.strftime(fetched_at_format) }
    let(:expected_response) { construct_response(records, sources) }

    subject { ExternalApi::EfolderService.generate_efolder_request(vbms_id, user, 3) }

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
        allow(HTTPI).to receive(:post).with(instance_of(HTTPI::Request)).and_return(expected_response)
      end

      context "when both sources come back as successful" do
        let(:records) do
          [
            {
              id: "1",
              type_id: "97",
              external_document_id: expected_document1.vbms_document_id,
              received_at: expected_received_at1,
              upload_date: expected_received_at1,
              series_id: expected_document1.series_id
            },
            {
              id: "2",
              type_id: "73",
              external_document_id: expected_document2.vbms_document_id,
              received_at: expected_received_at2,
              upload_date: expected_received_at2,
              series_id: expected_document2.series_id
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
          Generators::Document.build(
            type: "SSOC",
            filename: nil,
            file_number: appeal.sanitized_vbms_id,
            upload_date: expected_received_at1
          )
        end
        let(:expected_document2) do
          Generators::Document.build(
            type: "NOD",
            filename: nil,
            file_number: appeal.sanitized_vbms_id,
            upload_date: expected_received_at2
          )
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
              received_at: expected_received_at1,
              upload_date: expected_received_at1,
              series_id: expected_document1.series_id
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
          Generators::Document.build(
            type: "SSOC",
            filename: nil,
            file_number: appeal.sanitized_vbms_id,
            upload_date: expected_received_at1
          )
        end

        it "should make another request if pending status" do
          expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request))
            .and_return(expected_response)
          expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request))
            .and_return(expected_response2)
          expected_document1.received_at = expected_received_at1.to_s
          subject[:documents] = subject[:documents].map(&:to_hash)
          expect(subject).to eq(expected_result)
        end
      end

      context "when 404 HTTP error" do
        let(:expected_response) { HTTPI::Response.new(404, [], {}.to_json) }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { subject }.to(raise_error) do |e|
            expect(e).to be_a(Caseflow::Error::DocumentRetrievalError)
            expect(e.message).to eq("Failed for #{vbms_id}, user_id: #{user.id}, error: {}, HTTP code: 404")
          end
        end
      end

      context "when 400 HTTP error" do
        let(:expected_response) { HTTPI::Response.new(400, [], {}.to_json) }

        it "throws Caseflow::Error::ClientRequestError" do
          expect { subject }
            .to raise_error(Caseflow::Error::ClientRequestError)
        end
      end

      context "when 403 HTTP error" do
        let(:expected_response) { HTTPI::Response.new(403, [], { status: "forbidden: sensitive record" }.to_json) }

        it "throws Caseflow::Error::EfolderAccessForbidden" do
          expect { subject }.to(raise_error) do |e|
            expect(e).to be_a(Caseflow::Error::EfolderAccessForbidden)
            expect(e.code).to eq(403)
          end
        end
      end

      context "when 500 HTTP error" do
        let(:expected_response) { HTTPI::Response.new(500, [], { status: "terrible error" }.to_json) }

        it "throws Caseflow::Error::DocumentRetrievalError" do
          expect { subject }.to(raise_error) do |e|
            expect(e).to be_a(Caseflow::Error::DocumentRetrievalError)
            expect(e.code).to eq(502)
          end
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

      context "when both sources come back as pending" do
        let(:sources) do
          [
            {
              source: "VVA",
              status: "pending",
              fetched_at: manifest_vva_fetched_at
            },
            {
              source: "VBMS",
              status: "pending",
              fetched_at: manifest_vbms_fetched_at
            }
          ]
        end
        let(:records) { [] }

        let(:expected_result) do
          {
            documents: [],
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at
          }
        end
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

  def construct_response(records, sources)
    response = { data: { attributes: { records: records, sources: sources } } }
    HTTPI::Response.new(200, [], response.to_json)
  end
end
