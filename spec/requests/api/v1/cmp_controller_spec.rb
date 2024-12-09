# frozen_string_literal: true

shared_examples "a validates required params are not null #document endpoint" do |required_param|
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV1 Test #{required_param} CMP Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  let(:post_data) do
    {
      dateOfReceipt: 1.day.ago.strftime(Date::DATE_FORMATS[:csv_date]),
      documentId: SecureRandom.uuid,
      documentUuid: SecureRandom.uuid,
      nonVbmsDocTypeName: Faker::Internet.username(specifier: 8),
      packetUuid: SecureRandom.uuid,
      vbmsDocTypeId: Faker::Number.within(range: 1..10)
    }
  end

  it "does not save when missing the #{required_param} required param" do
    post_data[required_param] = nil

    expect do
      post(
        api_v1_cmp_document_path,
        params: post_data,
        as: :json,
        headers: authorization_header
      )
    end.not_to change(CmpDocument, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end
end

describe Api::V1::CmpController, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV1 Test CMP Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  describe "#document" do
    let!(:cmp_document_id) { SecureRandom.uuid }
    let!(:cmp_document_uuid) { SecureRandom.uuid }
    let!(:date_of_receipt) { 1.day.ago.strftime(Date::DATE_FORMATS[:csv_date]) }
    let!(:packet_uuid) { SecureRandom.uuid }
    let!(:doctype_name) { Faker::Internet.username(specifier: 8) }
    let!(:vbms_doctype_id) { Faker::Number.within(range: 1..10) }

    let(:post_data) do
      {
        dateOfReceipt: date_of_receipt,
        documentId: cmp_document_id,
        documentUuid: cmp_document_uuid,
        nonVbmsDocTypeName: doctype_name,
        packetUuid: packet_uuid,
        vbmsDocTypeId: vbms_doctype_id
      }
    end

    context "with valid params" do
      it "successfully creates a CMP document" do
        expect do
          post(
            api_v1_cmp_document_path,
            params: post_data,
            as: :json,
            headers: authorization_header
          )
        end.to change(CmpDocument, :count).by(1)

        expect(response).to have_http_status(:ok)

        cmp_document = CmpDocument.first
        expect(cmp_document.cmp_document_id).to eq(cmp_document_id)
        expect(cmp_document.cmp_document_uuid).to eq(cmp_document_uuid)
        expect(cmp_document.packet_uuid).to eq(packet_uuid)
        expect(cmp_document.date_of_receipt.strftime(Date::DATE_FORMATS[:csv_date])).to eq date_of_receipt
        expect(cmp_document.doctype_name).to eq(doctype_name)
        expect(cmp_document.vbms_doctype_id).to eq(vbms_doctype_id)
      end

      context "without optional params" do
        it "successfully creates a CMP document" do
          post_data[:nonVbmsDocTypeName] = nil

          expect do
            post(
              api_v1_cmp_document_path,
              params: post_data,
              as: :json,
              headers: authorization_header
            )
          end.to change(CmpDocument, :count).by(1)

          expect(response).to have_http_status(:ok)
          cmp_document = CmpDocument.first
          expect(cmp_document.doctype_name).to be_nil
        end
      end
    end

    context "with invalid params" do
      context "when required params are blank" do
        [:documentId, :documentUuid, :dateOfReceipt, :packetUuid, :vbmsDocTypeId].each do |required_param|
          it_should_behave_like "a validates required params are not null #document endpoint", required_param
        end
      end

      it "requires that the dateOfReceipt param is a valid date" do
        post_data[:dateOfReceipt] = "not really a date"

        expect do
          post(
            api_v1_cmp_document_path,
            params: post_data,
            as: :json,
            headers: authorization_header
          )
        end.not_to change(CmpDocument, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#packet" do
    let!(:cmp_document_id) { SecureRandom.uuid }
    let!(:cmp_document_uuid) { SecureRandom.uuid }
    let!(:date_of_receipt) { 1.day.ago.strftime(Date::DATE_FORMATS[:csv_date]) }
    let!(:packet_uuid) { SecureRandom.uuid }
    let!(:doctype_name) { Faker::Internet.username(specifier: 8) }
    let!(:vbms_doctype_id) { Faker::Number.within(range: 1..10) }

    let!(:packed_uuid) { SecureRandom.uuid }
    let!(:cmp_packet_number) { 1 }
    let!(:packet_source) { Faker::Internet.username(specifier: 8) }
    let!(:va_dor) { 1.hour.ago.strftime(Date::DATE_FORMATS[:csv_date]) }
    let!(:veteran) { create(:veteran, middle_name: 'M') }

    let(:post_data2) do
      {
        packetUUID: cmp_document_uuid,
        cmpPacketNumber: cmp_document_uuid,
        packetSource: packet_source,
        vaDor: va_dor,
        veteranId: veteran.id,
        veteranFirstName: veteran.first_name,
        veteranMiddleName: veteran.middle_name,
        veteranLastName: veteran.last_name
      }
    end

      let(:cmp_data) do
      {
            date_of_receipt: date_of_receipt,
            cmp_document_id: cmp_document_id,
            cmp_document_uuid: cmp_document_uuid,
            doctype_name: doctype_name,
            packet_uuid: packet_uuid,
            vbms_doctype_id: vbms_doctype_id
       }
      end

    context "with valid params" do
      it "returns 200" do
        CmpDocument.create!(cmp_data)
        expect do
          post(
            api_v1_cmp_packet_path,
            params: post_data2,
            as: :json,
            headers: authorization_header
          )
        end.not_to change(CmpDocument, :count)
        expect(response.status == 200)
      end

    end


  end
end
