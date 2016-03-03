require 'spec_helper'

describe 'Ruby Encrypt/Decrypt test vs Java reference impl' do
  let(:encrypted_xml) { fixture_path('encrypted_response.xml') }
  let(:plaintext_xml) { fixture_path('plaintext_basic_soap.xml') }
  let(:plaintext_unicode_xml) { fixture_path('plaintext_unicode_soap.xml') }
  let(:plaintext_request_name) { 'getDocumentTypes' }
  let(:test_jks_keystore) { fixture_path('test_keystore.jks') }
  let(:test_pc12_server_key) { fixture_path('test_keystore_vbms_server_key.p12') }
  let(:test_pc12_client_key) { fixture_path('test_keystore_importkey.p12') }
  let(:test_keystore_pass) { 'importkey' }

  it 'encrypts in ruby, and decrypts using java' do
    # TODO(awong): Implement encrypt in ruby.
    encrypted_xml = VBMS.encrypted_soap_document(
      plaintext_xml, test_jks_keystore, test_keystore_pass, plaintext_request_name)
    decrypted_xml = VBMS.decrypt_message_xml(encrypted_xml, test_jks_keystore,
                                             test_keystore_pass, 'log/decrypt.log')

    # Compare the decrypted request node with the original request node.
    original_doc = Nokogiri::XML(fixture('plaintext_basic_soap.xml'))
    original_request_node = original_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    decrypted_doc = Nokogiri::XML(decrypted_xml)
    decrypted_request_node = decrypted_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    expect(original_request_node).to be_equivalent_to(decrypted_request_node).respecting_element_order
  end

  it 'encrypts in java, and decrypts using ruby' do
    encrypted_xml = VBMS.encrypted_soap_document(
      plaintext_xml, test_jks_keystore, test_keystore_pass, plaintext_request_name)
    decrypted_xml = VBMS.decrypt_message_xml_ruby(encrypted_xml, test_pc12_server_key,
                                                  test_keystore_pass)

    # Compare the decrypted request node with the original request node.
    original_doc = Nokogiri::XML(fixture('plaintext_basic_soap.xml'))
    original_request_node = original_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    decrypted_doc = Nokogiri::XML(decrypted_xml)
    decrypted_request_node = decrypted_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    expect(original_request_node).to be_equivalent_to(decrypted_request_node).respecting_element_order
  end

  it 'handles roundtripping utf-8 content.' do
    pending('Correct Unicode Handling')
    encrypted_xml = VBMS.encrypted_soap_document(
      plaintext_unicode_xml, test_jks_keystore, test_keystore_pass, plaintext_request_name)
    decrypted_xml = VBMS.decrypt_message_xml(encrypted_xml, test_jks_keystore,
                                             test_keystore_pass, 'log/decrypt.log')

    # Compare the decrypted request node with the original request node.
    original_doc = Nokogiri::XML(fixture('plaintext_unicode_soap.xml'))
    original_request_node = original_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    decrypted_doc = Nokogiri::XML(decrypted_xml)
    decrypted_request_node = decrypted_doc.xpath(
      '/soapenv:Envelope/soapenv:Body/v4:getDocumentTypes',
      VBMS::XML_NAMESPACES)
    expect(decrypted_request_node).to be_equivalent_to(original_request_node).respecting_element_order
  end
end
