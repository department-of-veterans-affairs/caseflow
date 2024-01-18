# frozen_string_literal: true

describe DecisionReviewCreatedEvent, :postgres do
  describe "inheritance" do
    subject { DecisionReviewCreatedEvent.create!(reference_id: "1") }
    it "is a child class of Event and is the correct type" do
      subject.reload
      expect(Event.count).to eq(1)
      expect(Event.first.id).to eq(subject.id)
      expect(Event.first.type).to eq(subject.class.name)
    end
  end
end
