# frozen_string_literal: true

describe Annotation, :postgres do
  let(:annotation) do
    Annotation.new(document_id: document.id, comment: comment)
  end

  let(:document) { Document.create!(vbms_document_id: Random.rand(1..256)) }
  let(:comment) { Generators::Random.word_characters }

  context "#save" do
    context "when comment contains some word characters" do
      it "saves to database with correct comment text" do
        expect(annotation.comment.blank?).to be_falsy
        annotation.save!
        expect(Annotation.find(annotation.id).comment).to eq(comment)
      end
    end

    let(:err_msg) { "Validation failed: Comment can't be blank" }

    context "when comment is an empty string" do
      let(:comment) { "" }
      it "throws an error" do
        expect { annotation.save! }.to raise_error(ActiveRecord::RecordInvalid, err_msg)
      end
    end

    context "when comment contains only whitespace" do
      let(:comment) { Generators::Random.whitespace }
      it "throws an error" do
        expect { annotation.save! }.to raise_error(ActiveRecord::RecordInvalid, err_msg)
      end
    end
  end
end
