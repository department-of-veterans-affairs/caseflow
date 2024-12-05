# frozen_string_literal: true

describe ReaderPreferences do
  context ".get" do
    context "ENV value exists for prefrence" do
      it "returns a value for preference" do
        expect(ReaderPreferences.get(:reader_delay_before_progress_bar)).to eq 1000
      end
    end
    context "ENV values does not exist for preference" do
      it "returns nil" do
        expect(ReaderPreferences.get(:not_saved_env_variable)).to eq nil
      end
    end
  end

  context ".set" do
    context "ENV value exists for prefrence" do
      it "sets a new value for preference" do
        expect { ReaderPreferences.set(:reader_delay_before_progress_bar, 3000) }
          .to change { ReaderPreferences.get(:reader_delay_before_progress_bar) }.to(3000)
      end

      it "returns an array with preference information" do
        expect(ReaderPreferences.set(:reader_delay_before_progress_bar, 3000))
          .to eq ["READER_DELAY_BEFORE_PROGRESS_BAR", 3000]
      end
    end
    context "ENV values does not exist for preference" do
      it "returns nil" do
        expect(ReaderPreferences.set(:not_saved_env_variable, 3000)).to eq nil
      end
    end
  end
  context ".delete" do
    context "ENV value exists for prefrence" do
      before do
        ReaderPreferences.set(:reader_delay_before_progress_bar, 3000)
      end
      it "resets preference to default value" do
        default_value = ENV["READER_DELAY_BEFORE_PROGRESS_BAR"].to_i

        expect { ReaderPreferences.delete(:reader_delay_before_progress_bar) }
          .to change { ReaderPreferences.get(:reader_delay_before_progress_bar) }.to(default_value)
      end

      it "returns an array with preference information" do
        expect(ReaderPreferences.delete(:reader_delay_before_progress_bar))
          .to eq ["READER_DELAY_BEFORE_PROGRESS_BAR", 1000]
      end
    end
    context "ENV values does not exist for preference" do
      it "returns nil" do
        expect(ReaderPreferences.delete(:not_saved_env_variable)).to eq nil
      end
    end
  end
end
