FactoryBot.define do
  factory :vbms_uploaded_document do
    appeal { create(:appeal) }
    document_type { "Status Letter" }
    file { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }
  end
end
