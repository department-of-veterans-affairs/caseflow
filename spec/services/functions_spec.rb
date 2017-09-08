require "spec_helper"

describe Functions do
  let(:user1) { OpenStruct.new(css_id: "5") }
  let(:user2) { OpenStruct.new(css_id: "7") }

  before :each do
    Functions.delete_all_keys!
  end

  context ".grant!" do
    context "for a set of users" do
      subject { Functions.grant!("Reader", users: [user1.css_id, user2.css_id]) }

      it "grants function to users" do
        subject
        expect(Functions.client.keys.include?("Reader")).to eq true
        expect(Functions.client.get("Reader").include?("\"granted\":[\"5\",\"7\"]")).to eq true
        expect(Functions.granted?("Reader", user1.css_id)).to eq true
        expect(Functions.granted?("Reader", user2.css_id)).to eq true
      end
    end

    context "for an empty set of users" do
      subject { Functions.grant!("Reader", users: []) }

      it "function has no granted users" do
        subject
        expect(Functions.granted?("Reader", user1.css_id)).to eq false
        expect(Functions.granted?("Reader", user2.css_id)).to eq false
      end
    end
  end

  context ".deny!" do
    context "for a set of users" do
      subject { Functions.deny!("Reader", users: [user1.css_id, user2.css_id]) }

      it "removes grant from users" do
        subject
        expect(Functions.granted?("Reader", user1.css_id)).to eq false
        expect(Functions.granted?("Reader", user2.css_id)).to eq false
      end

      it "denies function to users" do
        subject
        expect(Functions.denied?("Reader", user1.css_id)).to eq true
        expect(Functions.denied?("Reader", user2.css_id)).to eq true
      end
    end

    context "for an empty set of users" do
      subject { Functions.deny!("Reader", users: []) }

      it "function has no denied users" do
        subject
        expect(Functions.denied?("Reader", user1.css_id)).to eq false
        expect(Functions.denied?("Reader", user2.css_id)).to eq false
      end
    end
  end

  context ".functions" do
    context "when functions exist" do
      before do
        Functions.grant!("Reader", users: [user1.css_id])
        Functions.grant!("System Admin", users: [user1.css_id])
      end
      subject { Functions.functions.sort }

      it { is_expected.to eq ["Reader", "System Admin"] }
    end

    context "when functions do not exist" do
      subject { Functions.functions }

      it { is_expected.to eq [] }
    end
  end

  context ".details_for" do
    subject { Functions.details_for("Reader") }

    context "when not granted" do
      it { is_expected.to be nil }
    end

    context "when granted for a list of users" do
      before do
        Functions.grant!("Reader", users: [user1.css_id, user2.css_id])
      end
      it { is_expected.to eq(granted: [user1.css_id, user2.css_id]) }
    end
  end

  context ".granted?" do
    context "when a function does not exist in redis" do
      subject { Functions.granted?("Foo", user1.css_id) }

      it { is_expected.to eq false }
    end

    context "for a set of users" do
      before do
        Functions.deny!("Reader", users: [user1.css_id])
        Functions.grant!("Reader", users: [user1.css_id, user2.css_id])
      end

      it "granted" do
        expect(Functions.denied?("Reader", user1.css_id)).to eq false
        expect(Functions.granted?("Reader", user1.css_id)).to eq true
        expect(Functions.granted?("Reader", user2.css_id)).to eq true
        expect(Functions.granted?("Reader", "Foo")).to eq false
      end
    end
  end

  context ".denied?" do
    context "when a function does not exist in redis" do
      subject { Functions.denied?("Foo", user1.css_id) }

      it { is_expected.to eq false }
    end

    context "for a set of users" do
      before do
        Functions.grant!("Reader", users: [user1.css_id])
        Functions.deny!("Reader", users: [user1.css_id, user2.css_id])
      end

      it "denied" do
        expect(Functions.granted?("Reader", user1.css_id)).to eq false
        expect(Functions.denied?("Reader", user1.css_id)).to eq true
        expect(Functions.denied?("Reader", user2.css_id)).to eq true
        expect(Functions.denied?("Reader", "Foo")).to eq false
      end
    end
  end

  context ".list_all" do
    subject { Functions.list_all }

    context "when a function does not exist in redis, it should be empty" do
      it { expect(subject).to be_empty }
    end

    context "when there is a list of granted and denied users" do
      before do
        Functions.grant!("System Admin", users: [user1.css_id, user2.css_id])
        Functions.deny!("System Admin", users: ["Foo"])
        Functions.grant!("Reader", users: [user1.css_id, user2.css_id])
      end

      it "returns a hash" do
        expect(subject).to include("Reader" => { granted: %w(5 7) },
                                   "System Admin" => { granted: %w(5 7), denied: ["Foo"] })
      end
    end
  end
end
