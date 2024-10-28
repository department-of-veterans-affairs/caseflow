# frozen_string_literal: true

RSpec.describe CmpDocument, type: :model do
  it { should validate_presence_of(:cmp_document_id) }
  it { should validate_presence_of(:cmp_document_uuid) }
  it { should validate_presence_of(:date_of_receipt) }
  it { should validate_presence_of(:packet_uuid) }
  it { should validate_presence_of(:vbms_doctype_id) }

  it { should belong_to(:cmp_mail_packet).optional }
end
