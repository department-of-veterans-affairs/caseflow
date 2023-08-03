
class TextExtractor
  def initialize(textract_client)
    @textract_client = textract_client
  end

  def extract_text(image_data)

    response = @textract_client.analyze_document(
      feature_types: ['TABLES', 'FORMS'],
      document: { bytes: image_data }
    )
    
    extracted_text = ''
    response.blocks.each do |block|
      extracted_text += block.text if block.block_type == 'LINE'
    end
    extracted_text
  end
end
