# frozen_string_literal: true

fdescribe Asyncable do #TODO remove f
  class TestAsyncable
    include ActiveModel::Model
    include Asyncable

    attr_accessor :submitted_at, :attempted_at, :processed_at, :canceled_at

    def [](column) # access attrs as if they were activerecord columns
      name = column.match(/^\w+_at/).to_s
      self.send(name.to_sym)
    end
  end

  # let(:model) { TestAsyncable.new(regional_office_key: "RO22") }

  describe "#asyncable_status" do
    it 'should return :not_yet_submitted if there is no timestamps' do
      subject = TestAsyncable.new
      expect(subject.asyncable_status).to eq :not_yet_submitted
    end
    it 'should return :processed when the processed timestamp is set'
    it 'should return :canceled when the canceled timestamp is set'
    it 'should return :attempted when the attempted timestamp is set'
    it 'should return :submitted when the submitted timestamp is set'
    # TODO add cases with multiple timestamps
  end
end
