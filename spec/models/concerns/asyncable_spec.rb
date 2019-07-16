# frozen_string_literal: true

describe Asyncable do
  class TestAsyncable
    include ActiveModel::Model
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
      t = Time.zone.now
      subject = TestAsyncable.new(submitted_at: t - 10.minutes, attempted_at: t - 5.minutes, processed_at: t)
      expect(subject.asyncable_status).to eq :processed
    end
    it "should return :canceled when the canceled timestamp is set" do
      t = Time.zone.now
      subject = TestAsyncable.new(submitted_at: t - 10.minutes, attempted_at: t - 5.minutes, canceled_at: t)
      expect(subject.asyncable_status).to eq :canceled
    end
    it "should return :attempted when the attempted timestamp is set" do
      t = Time.zone.now
      subject = TestAsyncable.new(submitted_at: t - 5.minutes, attempted_at: t)
      expect(subject.asyncable_status).to eq :attempted
    end
    it "should return :submitted when the submitted timestamp is set" do
      subject = TestAsyncable.new(submitted_at: Time.zone.now)
      expect(subject.asyncable_status).to eq :submitted
    end
  end
end
