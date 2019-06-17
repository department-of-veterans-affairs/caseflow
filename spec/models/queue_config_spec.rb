# frozen_string_literal: true

describe QueueConfig do
  describe ".new" do
    let(:arguments) { { organization: organization } }

    subject { QueueConfig.new(arguments) }

    context "when object is created with no arguments" do
      let(:arguments) { {} }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a nil organization" do
      let(:organization) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a valid organization" do
      let(:organization) { FactoryBot.create(:organization) }

      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe ".to_hash_for_user" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:user) { FactoryBot.create(:user) }

    subject { QueueConfig.new(organization: organization).to_hash_for_user(user) }

    describe "shape of the returned hash" do
      it "returns the correct top level keys in the response" do
        expect(subject.keys).to match_array([:table_title, :active_tab, :tabs])
      end
    end

    describe "title" do
      it "is formatted as expected" do
        expect(subject[:table_title]).to eq(format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name))
      end
    end

    describe "active_tab" do
      it "is always the unassigned tab" do
        expect(subject[:active_tab]).to eq(Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME)
      end
    end

    describe "tabs" do
      subject { QueueConfig.new(organization: organization).to_hash_for_user(user)[:tabs] }

      context "with a non-VSO organization" do
        it "does not include a tab for tracking tasks" do
          expect(subject.length).to eq(3)
          expect(subject.pluck(:name)).to_not include(Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME)
        end

        it "has the correct shape for each tab hash" do
          subject.each do |tab|
            expect(tab.keys).to match_array(
              [:label, :name, :description, :columns, :task_group, :allow_bulk_assign, :tasks]
            )
          end
        end

        it "does not include the regional column in the list of columns for any tab" do
          subject.each do |tab|
            expect(tab[:columns]).to_not include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
          end
        end
      end

      context "with an organization that displays regional office in " do
        before { allow(organization).to receive(:show_regional_office_in_queue?).and_return(true) }

        it "includes the regional column in the list of columns for all tabs" do
          subject.each do |tab|
            expect(tab[:columns]).to include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
          end
        end
      end

      context "when a VSO" do
        let(:organization) { FactoryBot.create(:vso) }

        it "includes a tab for tracking tasks" do
          expect(subject.length).to eq(4)
          expect(subject.pluck(:name)).to include(Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME)
        end

        it "has the correct shape for each tab hash" do
          subject.each do |tab|
            expect(tab.keys).to match_array(
              [:label, :name, :description, :columns, :task_group, :allow_bulk_assign, :tasks]
            )
          end
        end
      end
    end
  end
end
