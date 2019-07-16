# frozen_string_literal: true

describe Asyncable do
  class TestAsyncable
    include ActiveModel::Model
    include Asyncable

    attr_accessor :test_relevant_fields
  end

  # let(:model) { TestAsyncable.new(regional_office_key: "RO22") }

  describe "#asyncable_status" do
    it 'should return :not_yet_submitted if there is no timestamps'
    it 'should return :processed when the processed timestamp is set'
    it 'should return :canceled when the canceled timestamp is set'
    it 'should return :attempted when the attempted timestamp is set'
    it 'should return :submitted when the submitted timestamp is set'
    # TODO add cases with multiple timestamps
  end
end
