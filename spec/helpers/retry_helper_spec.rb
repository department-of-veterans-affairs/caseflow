# frozen_string_literal: true

class TestClass
  include RetryHelper

  attr_accessor :limit, :call_count, :fail_on_counts

  def initialize(limit, fail_on_counts)
    @call_count = 0
    @limit = limit
    @fail_on_counts = fail_on_counts
  end

  def retry_method
    retry_when StandardError, limit: @limit do
      @call_count += 1
      fail "fun-error" if @fail_on_counts.include?(@call_count)
    end
  end
end

RSpec.describe RetryHelper, type: :helper do
  describe "#retry_when" do
    let(:fail_on_counts) { [] }
    let(:limit) { 1 }
    let(:obj) { TestClass.new(limit, fail_on_counts) }
    subject { obj.retry_method }

    it "yields the block" do
      subject
      expect(obj.call_count).to eq(1)
    end

    context "when an error is raised once" do
      # Raise error on first loop through
      let(:fail_on_counts) { [1] }

      it "will retry" do
        subject
        expect(obj.call_count).to eq(2)
      end
    end

    context "when an error is raised more than once" do
      # raise error on first 3 calls
      let(:fail_on_counts) { [1, 2, 3] }
      let(:limit) { 2 }

      it "will retry until limit " do
        expect { subject }.to raise_error("fun-error")
        expect(obj.call_count).to eq(limit + 1) # plus one for the original call
      end
    end
  end
end
