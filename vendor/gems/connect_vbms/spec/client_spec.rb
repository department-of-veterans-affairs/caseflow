require 'spec_helper'

describe VBMS::Client do
  before(:example) do
    @client = VBMS::Client.new(
      'http://test.endpoint.url/', nil, nil, nil, nil, nil, nil
    )
  end

  describe 'remove_must_understand' do
    it 'takes a Nokogiri document and deletes the mustUnderstand attribute' do
      doc = Nokogiri::XML(<<-EOF)
      <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope
           xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
           xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
        <soapenv:Header>
          <wsse:Security soapenv:mustUnderstand="1">
          </wsse:Security>
        </soapenv:Header>
      </soapenv:Envelope>
      EOF

      @client.remove_must_understand(doc)

      expect(doc.to_s).not_to include('mustUnderstand')
    end
  end

  describe '#send' do
    before do
      @client = VBMS::Client.new(
        'http://test.endpoint.url/', nil, nil, nil, nil, nil, nil
      )

      @request = double('request',
                        file_number: '123456788',
                        received_at: DateTime.new(2010, 01, 01),
                        first_name: 'Joe',
                        middle_name: 'Eagle',
                        last_name: 'Citizen',
                        exam_name: 'Test Fixture Exam',
                        pdf_file: '',
                        doc_type: '',
                        source: 'CUI tests',
                        name: 'uploadDocumentWithAssociations',
                        new_mail: '',
                        render_xml: '<xml></xml>'
                       )
      @response = double('response', code: 200, body: 'response')
    end

    it 'creates two log messages' do
      body = Nokogiri::XML('<xml>body</xml')
      allow_any_instance_of(HTTPClient).to receive(:post).and_return(@response)
      allow(@client).to receive(:process_response).and_return(nil)
      allow(VBMS).to receive(:encrypted_soap_document_xml).and_return(body.to_s)
      allow(@client).to receive(:inject_saml)
      allow(@client).to receive(:remove_must_understand)
      allow(@client).to receive(:create_body).and_return(body.to_s)
      allow(@client).to receive(:process_body)

      expect(@client).to receive(:log).with(:unencrypted_xml, unencrypted_body: @request.render_xml)
      expect(@client).to receive(:log).with(:request, response_code: @response.code,
                                                      request_body: body.to_s,
                                                      response_body: @response.body,
                                                      request: @request,
                                                      duration: Float)

      @client.send_request(@request)
    end
  end

  describe 'multipart_boundary' do
    it 'should extract the boundary from the header' do
      headers = {
        'Content-Type' => 'multipart/related; '\
                          'type="application/xop+xml"; '\
                          'boundary="uuid:a10f73c8-60e9-4985-ab2c-ac5fcd8baf2d"; '\
                          'start="<root.message@cxf.apache.org>"; '\
                          'start-info="text/xml"'
      }

      expect(@client.multipart_boundary(headers)).to eq('uuid:a10f73c8-60e9-4985-ab2c-ac5fcd8baf2d')
    end
  end

  describe 'from_env_vars' do
    let(:vbms_env_vars) do
      { 'CONNECT_VBMS_ENV_DIR' => '/my/path/to/credentials',
        'CONNECT_VBMS_URL' => 'http://example.com/fake_vbms',
        'CONNECT_VBMS_KEYFILE' => 'fake_keyfile.some_ext',
        'CONNECT_VBMS_SAML' => 'fake_saml_token',
        'CONNECT_VBMS_KEY' => 'fake_keyname',
        'CONNECT_VBMS_KEYPASS' => 'fake_keypass',
        'CONNECT_VBMS_CACERT' => 'fake_cacert',
        'CONNECT_VBMS_CERT' => 'fake_cert' }
    end

    before(:each) do
      allow_any_instance_of(HTTPClient::SSLConfig).to receive(:set_trust_ca)
      allow_any_instance_of(HTTPClient::SSLConfig).to receive(:set_client_cert_file)
    end

    it 'smoke test that it initializes when all environment variables are set' do
      stub_const('ENV', vbms_env_vars)
      expect(VBMS::Client.from_env_vars).not_to be_nil
    end

    describe 'required environment variables' do
      it 'needs CONNECT_VBMS_ENV_DIR set' do
        vbms_env_vars.delete('CONNECT_VBMS_ENV_DIR')
        stub_const('ENV', vbms_env_vars)
        expect { VBMS::Client.from_env_vars }.to raise_error(VBMS::EnvironmentError,
                                                             /CONNECT_VBMS_ENV_DIR must be set/)
      end

      it 'needs CONNECT_VBMS_URL set' do
        vbms_env_vars.delete('CONNECT_VBMS_URL')
        stub_const('ENV', vbms_env_vars)
        expect { VBMS::Client.from_env_vars }.to raise_error(VBMS::EnvironmentError,
                                                             /CONNECT_VBMS_URL must be set/)
      end

      it 'needs CONNECT_VBMS_KEYFILE set' do
        vbms_env_vars.delete('CONNECT_VBMS_KEYFILE')
        stub_const('ENV', vbms_env_vars)
        expect { VBMS::Client.from_env_vars }.to raise_error(VBMS::EnvironmentError,
                                                             /CONNECT_VBMS_KEYFILE must be set/)
      end

      it 'needs CONNECT_VBMS_SAML set' do
        vbms_env_vars.delete('CONNECT_VBMS_SAML')
        stub_const('ENV', vbms_env_vars)
        expect { VBMS::Client.from_env_vars }.to raise_error(VBMS::EnvironmentError,
                                                             /CONNECT_VBMS_SAML must be set/)
      end

      it 'needs CONNECT_VBMS_KEYPASS set' do
        vbms_env_vars.delete('CONNECT_VBMS_KEYPASS')
        stub_const('ENV', vbms_env_vars)
        expect { VBMS::Client.from_env_vars }.to raise_error(VBMS::EnvironmentError,
                                                             /CONNECT_VBMS_KEYPASS must be set/)
      end
    end

    describe 'required environment variables' do
      it 'needs CONNECT_VBMS_KEY set' do
        vbms_env_vars.delete('CONNECT_VBMS_KEY')
        stub_const('ENV', vbms_env_vars)
        expect(VBMS::Client.from_env_vars).not_to be_nil
      end

      it 'needs CONNECT_VBMS_CACERT set' do
        vbms_env_vars.delete('CONNECT_VBMS_CACERT')
        stub_const('ENV', vbms_env_vars)
        expect(VBMS::Client.from_env_vars).not_to be_nil
      end

      it 'needs CONNECT_VBMS_CERT set' do
        vbms_env_vars.delete('CONNECT_VBMS_CERT')
        stub_const('ENV', vbms_env_vars)
        expect(VBMS::Client.from_env_vars).not_to be_nil
      end
    end

    describe 'process_response' do
      let(:client) do
        VBMS::Client.new('http://test.endpoint.url/',
                         fixture_path('test_keystore.jks'),
                         fixture_path('test_samltoken.xml'),
                         nil,
                         'importkey',
                         nil, nil, nil)
      end

      let(:request) { double('request') }
      let(:response_body) { '' }
      let(:response) { double('response', content: response_body, headers: {}) }

      subject { client.process_response(request, response) }

      context 'when it is given valid encrypted XML' do
        let(:response_body) { encrypted_xml_file(fixture_path('requests/fetch_document.xml'), 'fetchDocumentResponse') }

        it 'should return a decrypted XML document' do
          expect(request).to receive(:handle_response) do |doc|
            expect(doc).to be_a(Nokogiri::XML::Document)
            expect(doc.at_xpath('//soapenv:Envelope', VBMS::XML_NAMESPACES)).to_not be_nil
          end

          expect { subject }.to_not raise_error
        end
      end

      context 'when it is given an unencrypted XML' do
        let(:response_body) { fixture_path('requests/fetch_document.xml') }

        it 'should raise a SOAPError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(VBMS::SOAPError)
            expect(error.message).to eq('Unable to parse SOAP message')
            expect(error.body).to eq(response_body)
          end
        end
      end

      context "when it is given a document that won't decrypt" do
        let(:response_body) do
          encrypted_xml_file(
            fixture_path('requests/fetch_document.xml'),
            'fetchDocumentResponse'
          ).gsub(
            %r{<xenc:CipherValue>.+</xenc:CipherValue>},
            '<xenc:CipherValue></xenc:CipherValue>'
          )
        end

        it 'should raise a SOAPError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(VBMS::SOAPError)
            expect(error.message).to eq('Unable to decrypt SOAP response')
            expect(error.body).to eq(response_body)
          end
        end
      end

      context 'when it is given a document that contains a SOAP fault' do
        let(:response_body) do
          <<-EOF
          <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Header/>
            <soap:Body>
              <soap:Fault>
                <faultcode>soap:Client</faultcode>
                <faultstring>Message does not have necessary info</faultstring>
                <faultactor>http://foo.com</faultactor>
                <detail>Detailed fault information</detail>
              </soap:Fault>
            </soap:Body>
          </soap:Envelope>
          EOF
        end

        it 'should raise a SOAPError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(VBMS::SOAPError)
            expect(error.message).to eq('SOAP Fault returned')
            expect(error.body).to eq(response_body)
          end
        end
      end

      context 'when the server sends an HTML response error page' do
        let(:response_body) do
          <<-EOF
            <html><head><title>An error has occurred</title></head>
            <body><p>I know you were expecting HTML, but sometimes sites do this</p></body>
            </html>
          EOF
        end

        it 'should raise a SOAPError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(VBMS::SOAPError)
            expect(error.message).to eq('No SOAP envelope found in response')
            expect(error.body).to eq(response_body)
          end
        end
      end
    end
  end
end
