# frozen_string_literal: true

describe RedactedAttributesConcern do
  context "LegacyHearing" do
    it "The RedactedAttributesConcern is included in the model" do
      expect(LegacyHearing < RedactedAttributesConcern).to eq true
    end

    it "attrs_to_redact" do
      expect(LegacyHearing.attrs_to_redact).to match_array(
        [
          { name: :notes, alias: true, class_method: true },
          { name: :judge_id, alias: true, class_method: true },
          { name: :user_id, alias: false },
          { name: :judge, alias: true, class_method: false }
        ]
      )
    end

    shared_context "LegacyHearing with notes and judge information" do
      let(:judge_user) { create(:user, :judge) }
      let(:notes_text) { "Sample text" }
      let!(:legacy_hearing) do
        create(:legacy_hearing).tap do |hear|
          hear.update!(user_id: judge_user.id)

          VACOLS::CaseHearing.find(hear.vacols_id).update!(notes1: notes_text)
        end
      end
    end

    context "As a Board employee" do
      include_context "LegacyHearing with notes and judge information"

      before { RequestStore[:current_user] = current_user }

      let(:current_user) { create(:hearings_coordinator) }

      it "Hearing notes are accessible" do
        expect(legacy_hearing.notes).to eq notes_text
      end

      it "Judge ID is accessible" do
        expect(legacy_hearing.judge_id).to eq judge_user.id
      end

      it "Judge's user ID is accessible" do
        expect(legacy_hearing.user_id).to eq judge_user.id
      end

      it "Judge instance method returns Judge user" do
        expect(legacy_hearing.judge.css_id).to eq judge_user.css_id
      end
    end

    context "As an unknown user" do
      include_context "LegacyHearing with notes and judge information"

      before { RequestStore[:current_user] = nil }

      it "Hearing notes are accessible" do
        expect(legacy_hearing.notes).to eq notes_text
      end

      it "Judge ID is accessible" do
        expect(legacy_hearing.judge_id).to eq judge_user.id
      end

      it "Judge's user ID is accessible" do
        expect(legacy_hearing.user_id).to eq judge_user.id
      end

      it "Judge instance method returns Judge user" do
        expect(legacy_hearing.judge.css_id).to eq judge_user.css_id
      end
    end

    context "As a non-Board employee" do
      include_context "LegacyHearing with notes and judge information"

      before { RequestStore[:current_user] = current_user }

      let(:current_user) { create(:user, :vso_role) }

      it "Hearing notes are redacted" do
        expect(legacy_hearing.notes).to be_nil
      end

      it "Judge ID is redacted" do
        expect(legacy_hearing.judge_id).to be_nil
      end

      it "Judge's user ID is redacted" do
        expect(legacy_hearing.user_id).to be_nil
      end

      it "Judge instance method redacts judge information" do
        expect(legacy_hearing.judge).to be_nil
      end
    end
  end
end
