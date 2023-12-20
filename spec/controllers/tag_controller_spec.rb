# frozen_string_literal: true

RSpec.describe TagController, :all_dbs, type: :controller do
  let!(:document) do
    Generators::Document.create(
      filename: "My NOD",
      type: "NOD",
      received_at: 1.day.ago,
      vbms_document_id: 3,
      tags: [
        Generators::Tag.create(text: "Tag1")
      ]
    )
  end

  let(:new_tag_text) { "Foo" }

  before do
    Fakes::Initializer.load!

    User.authenticate!(roles: ["System Admin"])
  end

  describe "#create" do
    it "should call the verify_access method" do
      expect_any_instance_of(TagController).to receive(:verify_access).exactly(1).times
      post :create, params: { document_id: document.id, tags: [{ text: new_tag_text }] }
    end

    it "should create a new tag" do
      expect(Tag.count).to eq(1)
      post :create, params: { document_id: document.id, tags: [{ text: new_tag_text }] }
      expect(Tag.count).to eq(2)
    end
  end

  describe "#destroy" do
    it "should remove specified tag from document, but doesn't delete" do
      expect(Tag.count).to eq(1)
      expect(document.tags.size).to eq(1)
      post :destroy, params: { document_id: document.id, id: document.tags[0].id }
      expect(Tag.count).to eq(1)
      expect(document.reload.tags.size).to eq(0)
    end
  end
end
