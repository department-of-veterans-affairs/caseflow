require 'rake'
require 'rails_helper'

describe 'Resolve multiple reviews' do
  before(:all) do
    # Load the Rakefile
    Rake.application.load_rakefile
  end

  let (:type) {hlr}

  describe 'rake reviews:resolve_multiple_reviews[type]' do
    it 'runs the resolve_multiple_reviews task' do
      expect_any_instance_of(rake reviews:resolve_multiple_reviews[type]).to receive(:type)
      Rake.application.invoke_task(reviews:resolve_multiple_reviews[type])
    end
  end

  describe 'resolve_duplicate_eps' do
    let(:review_ids) { '1,2,3' }

    it 'resolves duplicate end products for a list of reviews' do
      # Mock the reviews
      reviews = [double('HigherLevelReview'), double('SupplementalClaim')]
      allow(HigherLevelReview).to receive(:find_by).with(id: 1).and_return(reviews[0])
      allow(SupplementalClaim).to receive(:find_by).with(id: 2).and_return(reviews[1])
      allow(HigherLevelReview).to receive(:find_by).with(id: 3).and_return(nil)

      expect_any_instance_of(rake reviews:resolve_multiple_reviews[type]).to receive(:resolve_duplicate_eps).with(reviews)
      Rake.application.invoke_task(reviews:resolve_multiple_reviews[hlr])
    end
  end

  describe 'war_room:resolve_single_review' do
    let(:review_id) { 1 }
    let(:type) { 'hlr' }

    it 'resolves duplicate end products for a single review' do
      expect_any_instance_of(rake reviews:resolve_multiple_reviews[type]).to receive(:resolve_duplicate_eps).with(review_id, type)
      Rake.application.invoke_task(reviews:resolve_multiple_reviews[hlr])
    end

  end
end
