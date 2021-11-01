# frozen_string_literal: true

require "helpers/finder_console_methods.rb"

describe "FinderConsoleMethods" do
  let(:appeal) { create(:appeal) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, bfkey: "98765")) }

  class DummyClass end
  let(:console_shell) { DummyClass.new }
  before { console_shell.extend FinderConsoleMethods }

  describe "FinderConsoleMethods._appeal" do
    subject { console_shell._appeal(identifier) }
    context "identifier is a UUID" do
      let(:identifier) { appeal.uuid }
      it { is_expected.to eq appeal }
      # it "finds appeal" do
      #   expect(subject).to eq appeal
      # end
    end
    context "identifier is a vacols_id" do
      let(:identifier) { legacy_appeal.vacols_id }
      it { is_expected.to eq legacy_appeal }
    end
    context "identifier is a docket_number" do
      let(:identifier) { appeal.stream_docket_number }
      it { is_expected.to eq [[appeal], []] }

      context "AMA and legacy appeals have the same docket_number" do
        before { appeal.update(stream_docket_number: legacy_appeal.docket_number) }
        let(:identifier) { legacy_appeal.docket_number }
        it { is_expected.to eq [[appeal], [legacy_appeal]] }
      end
    end
  end
end
