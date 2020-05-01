# frozen_string_literal: true

describe Seeds::Tasks, :all_dbs do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      # TODO these are expensive to run, esp Facols.
      # make Seeds::Tasks less dependent on them.
      Seeds::Users.new.seed!
      #Seeds::Facols.new.seed!
    end

    it "creates all kinds of appeals and tasks" do
      expect { subject }.to_not raise_error
      expect(Task.count).to be > 500 # TODO get rid of rand-based logic
      expect(Appeal.count).to be > 200
    end
  end
end     
