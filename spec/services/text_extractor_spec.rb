
RSpec.describe TextExtractor, type: :service do
  describe '#extract_text' do
    let(:textract_client_double) { instance_double('Aws::Textract::Client') }
    let(:text_extractor) { TextExtractor.new(textract_client_double) }

    it 'extracts text from the given image' do

      response_double = double('response', blocks: [
        double('block', block_type: 'LINE', text: 'Extracted'),
        double('block', block_type: 'LINE', text: 'text'),
        double('block', block_type: 'TABLE', text: 'not extracted')
      ])

      allow(textract_client_double).to receive(:analyze_document).and_return(response_double)
      image_data = "CERTIFICATION THAT VALID POWER"
      extracted_text = text_extractor.extract_text(image_data)

      expect(extracted_text).to eq('Extractedtext')
    end


    it 'returns an empty string when there are no LINE blocks in the response' do
      response_double = double('response', blocks: [
        double('block', block_type: 'TABLE', text: 'Table 1'),
        double('block', block_type: 'TABLE', text: 'Table 2')
      ])

      allow(textract_client_double).to receive(:analyze_document).and_return(response_double)
      image_data = "APPEAL\n1A"
      extracted_text = text_extractor.extract_text(image_data)

      expect(extracted_text).to eq('')
    end

    it 'handles API request failure' do
      allow(textract_client_double).to receive(:analyze_document).and_return(double('response', blocks: []))
      image_data = "Department_data"
      extracted_text = text_extractor.extract_text(image_data)

      expect(extracted_text).to eq('')
    end
  end
end

