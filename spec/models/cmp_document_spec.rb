# frozen_string_literal: true

RSpec.describe CmpDocument, type: :model do
  it { should validate_presence_of(:cmp_document_id) }
  it { should validate_presence_of(:cmp_document_uuid) }
  it { should validate_presence_of(:packet_uuid) }

  it { should allow_value(Time.current.strftime(Date::DATE_FORMATS[:csv_date])).for(:date_of_receipt) }
  it { should_not allow_value(nil).for(:date_of_receipt) }
  it { should_not allow_value("19900101").for(:date_of_receipt) }
  it { should_not allow_value("0199-01-01").for(:date_of_receipt) }
  it { should_not allow_value("1999-122-31").for(:date_of_receipt) }
  it { should_not allow_value("1999-12-311").for(:date_of_receipt) }
  it { should_not allow_value("1999-12-32").for(:date_of_receipt) }
  it { should_not allow_value("not really a date").for(:date_of_receipt) }

  it { should allow_value(Faker::Number.within(range: 1..100).to_s).for(:vbms_doctype_id) }
  it { should_not allow_value(nil).for(:vbms_doctype_id) }
  it { should_not allow_value("not really an integer").for(:vbms_doctype_id) }

  it { should belong_to(:cmp_mail_packet).optional }
end
