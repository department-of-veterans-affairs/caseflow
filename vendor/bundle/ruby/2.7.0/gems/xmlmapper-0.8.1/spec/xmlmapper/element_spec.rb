require 'spec_helper'

describe XmlMapper::Element do
  describe "initialization" do
    before do
      @attr = XmlMapper::Element.new(:foo, String)
    end
  end
end
