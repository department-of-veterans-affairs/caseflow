require 'rails_helper'

describe Tag do
  let(:document) { Generators::Document.create(vbms_document_id: 123) } 
  
  context ".tag creation" do
    it "creates tag when valid text provided" do
      tag = Tag.new(text: "Service Disabled", document_id: document.id)
      assert tag.valid?
    end

    it "fails when document is not provided" do
      tag = Tag.new()
      refute tag.valid?, 'tag is not valid without a document'
    end

    it "fails when text not provided" do
      tag = Tag.new()
      refute tag.valid?, 'tag is not valid without text'
    end
  end
end
