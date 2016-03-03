require 'spec_helper'

describe VBMS::Responses::DocumentWithContent do
  describe 'create_from_xml' do
    let(:xml) { Nokogiri::XML(File.open(fixture_path('requests/fetch_document.xml'))) }
    let(:doc) { xml.at_xpath('//v4:result', VBMS::XML_NAMESPACES) }

    subject { VBMS::Responses::DocumentWithContent.create_from_xml(doc) }

    specify { expect(subject.document).to be_a(VBMS::Responses::Document) }
    specify { expect(subject.content).to be_a(String) }

    describe 'the associated document' do
      specify { expect(subject.document.document_id).to eq('{9E364101-AFDD-49A7-A11F-602CCF2E5DB5}') }
      specify { expect(subject.document.filename).to eq('tmp20150506-94244-6zotzp') }
      specify { expect(subject.document.doc_type).to eq('356') }
      specify { expect(subject.document.source).to eq('VHA_CUI') }
      specify { expect(subject.document.mime_type).to eq('text/plain') }
      specify { expect(subject.document.received_at).to eq(Date.parse('2015-05-06')) }
    end
  end

  describe 'serialization' do
    let(:document) { VBMS::Responses::Document.new }
    let(:content) { 'foo' }
    let(:attrs) { { document: document, content: content } }
    subject { VBMS::Responses::DocumentWithContent.new(attrs) }

    it 'should respond to to_h' do
      expect(subject.to_h).to be_a(Hash)
      expect(subject.to_h).to include(attrs)
    end

    it 'should respond to to_s' do
      expect(subject.to_s).to be_a(String)
    end

    it 'should contain the attributes in to_s' do
      expect(subject.to_s).to include(content)
    end

    it 'should respond to inspect with same response as to_s' do
      expect(subject.inspect).to eq(subject.to_s)
    end
  end
end
