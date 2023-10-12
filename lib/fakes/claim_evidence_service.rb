# frozen_string_literal: true

class Fakes::ClaimEvidenceService
  FAKE_STATUS = "sent"

  class << self
    def get_ocr_document(doc_series_id)
      ocr_data = <<~OCR_DATA
        Frodo: I can’t do this, Sam.

        Sam: I know. It’s all wrong. By rights we shouldn’t even be here. But we are. It’s like in the great stories, Mr. Frodo. The ones that really mattered. Full of darkness and danger, they were. And sometimes you didn’t want to know the end. Because how could the end be happy? How could the world go back to the way it was when so much bad had happened? But in the end, it’s only a passing thing, this shadow. Even darkness must pass. A new day will come. And when the sun shines it will shine out the clearer. Those were the stories that stayed with you. That meant something, even if you were too small to understand why. But I think, Mr. Frodo, I do understand. I know now. Folk in those stories had lots of chances of turning back, only they didn’t. They kept going. Because they were holding on to something.

        Frodo: What are we holding onto, Sam?

        Sam: That there’s some good in this world, Mr. Frodo... and it’s worth fighting for.
      OCR_DATA

      ocr_data
    end

    def document_types
    end
  end
end
