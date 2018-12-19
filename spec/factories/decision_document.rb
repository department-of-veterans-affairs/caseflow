FactoryBot.define do
  factory :decision_document do
  	appeal { create(:appeal) }
    citation_number { "A18123456" }
    decision_date { Time.zone.today }
    redacted_document_location { "C://Windows/User/BOBLAW/Documents/Decision.docx" }
  end
end
