require 'spec_helper'

def inflector
  m = ActiveSupport::Inflector.method('inflections')
  return ActiveSupport::Inflector.inflections(:en) if m.arity == 1
  ActiveSupport::Inflector.inflections
end

describe GovDelivery::TMS::CoreExt do

  subject do
    Object.new.extend(described_class)
  end

  describe '#camelize' do
    before do
      inflector do |inflect|
        inflect.acronym 'SMS'
      end
    end

    it 'should return camilized string not using inflector acronyms' do
      expect(subject.camelize('sms_message')).to eq 'SmsMessage'
    end
  end

end
