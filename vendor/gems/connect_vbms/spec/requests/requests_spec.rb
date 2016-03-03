require 'spec_helper'

describe VBMS::Requests do
  before(:example) do
    if ENV.key?('CONNECT_VBMS_RUN_EXTERNAL_TESTS')
      # We're doing it live and connecting to VBMS test server
      # otherwise, just use @client from above and webmock
      @client = VBMS::Client.from_env_vars
    else
      @client = VBMS::Client.new(
        'http://test.endpoint.url/', 
        fixture_path('test_keystore.jks'), 
        fixture_path('test_samltoken.xml'), 
        nil, 
        'importkey', nil, nil, nil
      )
    end
  end

  describe 'UploadDocumentWithAssociations' do
    it 'executes succesfully when pointed at VBMS' do
      Tempfile.open('tmp') do |t|
        request = VBMS::Requests::UploadDocumentWithAssociations.new(
          '784449089',
          Time.now,
          'Jane',
          'Q',
          'Citizen',
          'knee',
          t.path,
          '356',
          'Connect VBMS test',
          true
        )

        webmock_multipart_response(@client.endpoint_url,
                                   'upload_document_with_associations',
                                   'uploadDocumentWithAssociationsResponse')
        @client.send_request(request)

        # other tests?
      end
    end
  end

  describe 'ListDocuments' do
    it 'executes succesfully when pointed at VBMS' do
      request = VBMS::Requests::ListDocuments.new('784449089')

      webmock_soap_response(@client.endpoint_url, 'list_documents', 'listDocumentsResponse')
      @client.send_request(request)
    end
  end

  describe 'FetchDocumentById' do
    it 'executes succesfully when pointed at VBMS' do
      # Use ListDocuments to find a document to fetch

      webmock_soap_response(@client.endpoint_url, 'list_documents', 'listDocumentsResponse')

      request = VBMS::Requests::ListDocuments.new('784449089')
      result = @client.send_request(request)

      request = VBMS::Requests::FetchDocumentById.new(result[0].document_id)
      webmock_soap_response(@client.endpoint_url, 'fetch_document', 'fetchDocumentResponse')
      @client.send_request(request)
    end
  end

  describe 'GetDocumentTypes' do
    it 'executes succesfully when pointed at VBMS' do
      request = VBMS::Requests::GetDocumentTypes.new

      webmock_soap_response(@client.endpoint_url, 'get_document_types', 'getDocumentTypesResponse')
      result = @client.send_request(request)

      expect(result).not_to be_empty

      expect(result[0].type_id).to be_a_kind_of(String)
      expect(result[0].description).to be_a_kind_of(String)
    end
  end
end
