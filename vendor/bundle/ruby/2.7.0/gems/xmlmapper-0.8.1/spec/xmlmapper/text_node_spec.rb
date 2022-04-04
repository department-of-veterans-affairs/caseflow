require 'spec_helper'

describe XmlMapper::Attribute do
  describe "initialization" do
    before do
      @attr = XmlMapper::TextNode.new(:foo, String)
    end
  end
end
