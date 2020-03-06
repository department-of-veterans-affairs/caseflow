# frozen_string_literal: true

describe VeteranAttributeCacher, :postgres do
  context "local Veteran records exist with nil SSN or first_name" do
    let(:veteran_file_number_one) { "11111111" }
    let(:veteran_file_number_two) { "22222222" }
    let(:veteran_with_nil_ssn) do
      veteran_one.tap do |v|
        v.ssn = nil
        v.save!
      end
    end
    let(:veteran_with_nil_name) do
      veteran_two.tap do |v|
        v.first_name = nil
        v.save!
      end
    end
    let(:veteran_one) do
      Generators::Veteran.build(
        file_number: veteran_file_number_one
      )
    end
    let(:veteran_two) do
      Generators::Veteran.build(
        file_number: veteran_file_number_two
      )
    end

    it "caches attributes locally" do
      expect(veteran_with_nil_ssn[:ssn]).to be_nil # must use hash accessor to avoid bgs lookup
      expect(veteran_with_nil_name.first_name).to be_nil

      described_class.new.call

      expect(veteran_with_nil_ssn.reload[:ssn]).to_not be_nil
      expect(veteran_with_nil_name.reload.first_name).to_not be_nil
    end
  end
end
