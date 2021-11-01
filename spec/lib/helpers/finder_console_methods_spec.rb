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
      # before { binding.pry }
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
  describe "FinderConsoleMethods._veteran" do
    subject { console_shell._veteran(identifier) }
    let(:veteran) { appeal.veteran }
    context "identifier is a file_number" do
      let(:identifier) { veteran.file_number }
      it { is_expected.to eq [veteran, [appeal], [], []] }
    end
    context "identifier is a SSN" do
      let(:identifier) { veteran.ssn }
      it { is_expected.to eq [veteran, [appeal], [], []] }
    end
  end
  describe "FinderConsoleMethods._user" do
    subject { console_shell._user(identifier) }
    let(:appeal) { create(:appeal, :at_bva_dispatch) }
    let(:user) { appeal.tasks.find_by_type(:JudgeAssignTask).assigned_to }
    context "identifier is a User record id" do
      let(:identifier) { user.id }
      it { is_expected.to eq user }
    end
    context "identifier is a CSS_ID" do
      let(:identifier) { user.css_id }
      it { is_expected.to eq user }
    end
    context "identifier is a VACOLS::Staff slogid" do
      let(:identifier) { user.vacols_staff.slogid }
      it { is_expected.to eq user }
    end
    context "identifier is part of a full name" do
      let(:identifier) { user.full_name[] }
      it { is_expected.to eq user }

      context "identifier is part of a full name for multiple users" do
        it { is_expected.to eq [user, user2] }
      end
      context "identifier is a full name of a non-existing user" do
        it { is_expected.to eq nil }
      end
    end
  end
end
