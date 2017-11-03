describe Annotation do
  let(:annotation) do
    Annotation.new(document_id: document.id, comment: comment)
  end

  let(:document) { Document.create!(vbms_document_id: Random.rand(256) + 1) }
  let(:comment) { random_word_characters }

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
      let(:comment) { random_whitespace }
      it "throws an error" do
        expect { annotation.save! }.to raise_error(ActiveRecord::RecordInvalid, err_msg)
      end
    end
  end
end

# Generate some combination of whitespace characters between 1 and len characters long.
def random_whitespace(len = 16)
  random_sample([" ", "\n", "\r", "\t"], len)
end

# Generate some combination of word and space characters between 1 and len characters long.
def random_word_characters(len = 256)
  a = ("a".."z").to_a.concat(("A".."Z").to_a).concat(("0".."9").to_a).push("_")
  random_sample(a, len)
end

def random_sample(arr, len)
  (Array.new(Random.rand(len) + 1) { arr.sample }).join
end
