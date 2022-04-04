require 'spec_helper'

describe GovDelivery::TMS::Errors do
  context 'an errors hash' do
    let(:object_with_errors) do
      double('instance', href: 'href', errors: {'body' => ["can't be blank"], 'subject' => ["can't be blank"]})
    end
    subject { GovDelivery::TMS::Errors::InvalidVerb.new(object_with_errors) }
    it 'should work' do
      expect(subject.message).to match(/Couldn't POST/)
      expect(subject.message).to match(/body can't be blank, subject can't be blank/)
      expect(subject.error_message).to match(/body can't be blank, subject can't be blank/)
    end
  end
end
