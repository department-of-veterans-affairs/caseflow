require 'spec_helper'

describe VBMS::Responses::DocumentType do
  describe 'create_from_xml' do
    let(:xml_string) { File.open(fixture_path('requests/get_document_types.xml')).read }
    let(:xml) { Nokogiri::XML(xml_string) }
    let(:doc) { xml.at_xpath('//v4:result', VBMS::XML_NAMESPACES) }

    subject { VBMS::Responses::DocumentType.create_from_xml(doc) }

    specify { expect(subject.type_id).to eq('431') }
    specify { expect(subject.description).to eq('VA 21-4706c Court Appointed Fiduciarys Accounting') }
  end

  describe 'serialization' do
    let(:attrs) do
      { type_id: '431', description: 'VA 21-4706c Court Appointed Fiduciarys Accounting' }
    end
    subject { VBMS::Responses::DocumentType.new(attrs) }

    it 'should respond to to_h' do
      expect(subject.to_h).to be_a(Hash)
      expect(subject.to_h).to include(attrs)
    end

    it 'should respond to to_s' do
      expect(subject.to_s).to be_a(String)
    end

    it 'should contain the attributes in to_s' do
      s = subject.to_s
      expect(s).to include(attrs[:type_id])
      expect(s).to include(attrs[:description])
    end

    it 'should respond to inspect' do
      expect(subject.inspect).to eq(subject.to_s)
    end
  end
end
