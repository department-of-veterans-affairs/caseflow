# frozen_string_literal: true

describe FullName do
  let(:first) { "Charles" }
  let(:middle) { "E" }
  let(:last) { "Cheese" }
  let(:full_name) { FullName.new(first, middle, last) }

  context "#to_s" do
    subject { full_name.to_s }
    it { is_expected.to eq("Charles Cheese") }
  end

  context "#formatted" do
    subject { full_name.formatted(format) }

    context "readable_full" do
      let(:format) { :readable_full }

      it { is_expected.to eq("Charles E Cheese") }

      context "parts of the name are missing" do
        let(:middle) { nil }
        let(:last) { nil }
        it { is_expected.to eq("Charles") }
      end
    end

    context "readable_full_nonformatted" do
      let(:first) { "charles" }
      let(:format) { :readable_full_nonformatted }

      it { is_expected.to eq("charles E Cheese") }

      context "parts of the name are missing" do
        let(:middle) { nil }
        let(:last) { nil }
        it { is_expected.to eq("charles") }
      end
    end

    context "readable_short" do
      let(:format) { :readable_short }

      it { is_expected.to eq("Charles Cheese") }
    end

    context "readable_mi_formatted" do
      let(:format) { :readable_mi_formatted }

      it { is_expected.to eq("Charles E. Cheese") }
    end

    context "form" do
      let(:format) { :form }

      it { is_expected.to eq("Cheese, Charles, E") }

      context "parts of the name are missing" do
        let(:middle) { nil }
        it { is_expected.to eq("Cheese, Charles") }
      end
    end
  end
end
