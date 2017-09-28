require "rails_helper"

describe CachedAttributes do
  class TestThing
    include CachedAttributes

    attr_accessor :not_cached_rating

    # ID is required to create a key to store the hash
    def id
      "AN_ID"
    end

    cache_attribute :rating do
      not_cached_rating
    end
  end

  let(:model) { TestThing.new }

  context ".clear_cached_attrs!" do
    it "clears the cached attributes" do
      model.not_cached_rating = 10
      model.rating
      model.clear_cached_attr!(:rating)
      model.not_cached_rating = 9
      expect(model.rating).to eq(9)
    end
  end

  context "assign cache value" do
    it "saves assigned cache value" do
      model.rating = true
      model.not_cached_rating = false
      expect(model.rating).to eq(true)
    end
  end

  context ".cache_attribute" do
    subject { model.rating }
    before do
      model.clear_cached_attr!(:rating)
      model.not_cached_rating = 10
    end

    context "when no cached value" do
      before do
        model.not_cached_rating = 9
      end
      it { is_expected.to eq(9) }
    end

    context "caches false boolean values" do
      before do
        model.clear_cached_attr!(:rating)
        model.not_cached_rating = false
      end
      it "reads from cache" do
        expect(model.rating).to eq(false)
        model.not_cached_rating = true
        expect(model.rating).to eq(false)
      end
    end

    context "when cached value" do
      before do
        model.rating
        model.not_cached_rating = 9
      end

      it { is_expected.to eq(10) }
    end
  end
end
