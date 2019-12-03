# frozen_string_literal: true

context Api::V3::DecisionReview::DigError do
  context "::Quoted" do
    context "#to_s" do
      subject {Api::V3::DecisionReview::DigError::Quoted.new(value).to_s}

      context do
        let(:value) {12}
        it { is_expected.to eq("12") }
      end

      context do
        let(:value) {"hola"}
        it("has quotes") { is_expected.to eq('"hola"') }
      end

      context do
        let(:value) {nil}
        it("isn't blank") { is_expected.to eq("nil") }
      end

      context do
        let(:value) {{a: 1, b: 2}}
        it { is_expected.to eq("{:a=>1, :b=>2}") }
      end
    end
  end

  context "::PathString" do
    context "#to_s" do
      subject {Api::V3::DecisionReview::DigError::PathString.new(path).to_s}

      context do
        let(:path) {[:a, :b, :c]}
        it do
          is_expected.to eq("[a][b][c]")
        end
      end

      context do
        let(:path) {["a", "b", "c"]}
        it do
          is_expected.to eq('["a"]["b"]["c"]')
        end
      end

      context do
        let(:path) {[:a, 0, "b", nil, [1,2,3]]}
        it do
          is_expected.to eq('[a][0]["b"][nil][[1, 2, 3]]')
        end
      end
    end
  end

  context "::ValuesString" do
    context "#to_s" do
      subject {Api::V3::DecisionReview::DigError::ValuesString.new(values).to_s}

      context do
        let(:values) {[:a, :b, :c]}
        it 'is preceded by "one of"' do
          is_expected.to eq("one of [:a, :b, :c]")
        end
      end

      context do
        let(:values) {["This rather short sentence."]}
        it "should have quotes" do
          is_expected.to eq('"This rather short sentence."')
        end
      end

      context do
        let(:values) {[Integer]}
        it "has an indefinite article" do
          is_expected.to eq("a(n) integer")
        end
      end
    end
  end

  context ".to_s" do
    subject do
      Api::V3::DecisionReview::DigError.new(hash: hash, path: path, values: values).to_s
    end

    context do
      let(:hash) do
        {a: {b: {c: "hello"}, d: [8088, {e: ["goodbye"]}]}}
      end
      
      context do
        let(:path) do
          [:a, :b, :c]
        end

        let(:values) do
          ["hello"]
        end

        it { is_expected.to be(nil) }
      end
    end
  end
end
