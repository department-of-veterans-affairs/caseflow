require 'spec_helper'

describe XmlMapper::Attribute do

  describe "initialization" do
    it 'accepts :default option' do
      attr = described_class.new(:foo, String, :default => 'foobar')
      attr.default.should == 'foobar'
    end
  end

end
