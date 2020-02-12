# frozen_string_literal: true

describe Tag, :postgres do
  let(:document) { Generators::Document.create(vbms_document_id: 123) }
  let(:tag1) { Generators::Tag.create(text: "Service Connected") }

  context ".tag creation" do
    it "creates tag when valid text provided" do
      tag = Tag.new(text: "Service Disabled")
      assert tag.valid?
    end

    it "fails when text not provided" do
      tag = Tag.new
      refute tag.valid?, "tag is not valid without text"
    end

    it "can't add the same tag twice to a document" do
      num_of_tags = document.tags.size
      document.tags << tag1
      expect { document.tags << tag1 }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(document.tags.size).to eq(num_of_tags + 1)
    end
  end
end
