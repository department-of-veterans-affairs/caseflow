require 'spec_helper'

describe VBMS::Requests::UploadDocumentWithAssociations do
  subject do 
    VBMS::Requests::UploadDocumentWithAssociations.new(
      '123456788',
      Time.now.utc,
      'Joe', 'Eagle', 'Citizen',
      'UDWA test exam name',
      '/pdf/does/not/exist',
      'doc_type',
      'UDWA test source',
      'UDWA new mail')
  end

  describe 'render_xml' do
    it 'generates valid XML' do
      xml = subject.render_xml
      xsd = Nokogiri::XML::Schema(File.read('spec/soap.xsd'))
      expect(xsd.errors).to eq []
      errors = xsd.validate(parse_strict(xml))
      expect(errors).to eq []
    end
  end

  describe 'parsing the XML' do
    before do
      xml = File.read(fixture_path('requests/upload_document_with_associations.xml'))
      @doc = parse_strict(xml)
      @response = subject.handle_response(@doc)
    end

    it 'should just return the document' do
      expect(@response).to eq(@doc)
    end
  end
end
