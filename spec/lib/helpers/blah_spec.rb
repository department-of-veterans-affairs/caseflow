# frozen_string_literal: true

require "helpers/blah.rb"


describe Blah, :postgres do
  context "here" do
    it "is here" do
      Blah.new.boom
    end
  end
end
