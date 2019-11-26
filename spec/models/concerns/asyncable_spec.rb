# frozen_string_literal: true

describe Asyncable do
  class TestAsyncable
    include ActiveModel::Model

    # make Asyncable's has_many association(s) a no-op for these tests
    def self.has_many(*); end
    include Asyncable

    attr_accessor :submitted_at, :attempted_at, :processed_at, :canceled_at

    # access attrs as if they were activerecord columns
    def [](column)
      send(column.to_sym)
    end
  end

  describe "#asyncable_status" do
    it "should return :not_yet_submitted if there is no timestamps" do
      subject = TestAsyncable.new
      expect(subject.asyncable_status).to eq :not_yet_submitted
    end
    it "should return :processed when the processed timestamp is set" do
      now = Time.zone.now
      subject = TestAsyncable.new(submitted_at: now - 10.minutes, attempted_at: now - 5.minutes, processed_at: now)
      expect(subject.asyncable_status).to eq :processed
    end
    it "should return :canceled when the canceled timestamp is set" do
      now = Time.zone.now
      subject = TestAsyncable.new(submitted_at: now - 10.minutes, attempted_at: now - 5.minutes, canceled_at: now)
      expect(subject.asyncable_status).to eq :canceled
    end
    it "should return :attempted when the attempted timestamp is set" do
      now = Time.zone.now
      subject = TestAsyncable.new(submitted_at: now - 5.minutes, attempted_at: now)
      expect(subject.asyncable_status).to eq :attempted
    end
    it "should return :submitted when the submitted timestamp is set" do
      subject = TestAsyncable.new(submitted_at: Time.zone.now)
      expect(subject.asyncable_status).to eq :submitted
    end
  end
end
