require "spec_helper"

describe Xmlenc::Builder::RetrievalMethod do

  it 'has a tag' do
    expect(described_class.tag_name).to eq 'RetrievalMethod'
  end

  it 'has a namespace' do
    expect(described_class.namespace).to eq 'ds'
  end

  describe "optional fields" do
    subject { described_class.new }

    [:type, :uri].each do |field|
      it "should have the #{field} field" do
        expect(subject).to respond_to field
      end

      it "should allow #{field} to be blank" do
        subject.send("#{field}=", nil)
        expect(subject).to be_valid
      end
    end
  end

  describe '#parse' do
    let(:xml) { File.read File.join('spec', 'fixtures', 'encrypted_document.xml') }
    subject   { described_class.parse(xml, :single => true) }

    it 'should parse' do
      expect(subject).to be_a described_class
    end

    it 'should parse the URI' do
      expect(subject.uri).to eq '#_EK'
    end
  end

end
