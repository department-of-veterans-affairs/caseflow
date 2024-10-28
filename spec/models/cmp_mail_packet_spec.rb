# frozen_string_literal: true

RSpec.describe CmpMailPacket, type: :model do
  it { should validate_presence_of(:cmp_packet_number) }
  it { should validate_presence_of(:packet_source) }
  it { should validate_presence_of(:packet_uuid) }
  it { should validate_presence_of(:va_dor) }
  it { should validate_presence_of(:veteran_first_name) }
  it { should validate_presence_of(:veteran_id) }
  it { should validate_presence_of(:veteran_last_name) }
  it { should validate_presence_of(:veteran_middle_initial) }

  it { should have_many(:cmp_documents) }
end
