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
        expect(subject.keys).to match_array([:table_title, :active_tab, :tasks_per_page, :use_task_pages_api, :tabs])
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

      before { FeatureToggle.enable!(:use_task_pages_api) }
      after { FeatureToggle.disable!(:use_task_pages_api) }

      context "with a non-VSO organization" do
        it "does not include a tab for tracking tasks" do
          expect(subject.length).to eq(3)
          expect(subject.pluck(:name)).to_not include(Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME)
        end

        it "has the correct shape for each tab hash" do
          subject.each do |tab|
            expect(tab.keys).to match_array(
              [
                :label,
                :name,
                :description,
                :columns,
                :allow_bulk_assign,
                :tasks,
                :task_page_count,
                :total_task_count,
                :task_page_endpoint_base_path
              ]
            )
          end
        end

        it "does not include the regional column in the list of columns for any tab" do
          subject.each do |tab|
            expect(tab[:columns]).to_not include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
          end
        end

        context "when the organization uses the task pages API and has tasks assigned to it" do
          before { FeatureToggle.enable!(:use_task_pages_api) }
          after { FeatureToggle.disable!(:use_task_pages_api) }

          let!(:unassigned_tasks) { FactoryBot.create_list(:generic_task, 4, assigned_to: organization) }
          let!(:on_hold_tasks) { FactoryBot.create_list(:generic_task, 2, :on_hold, assigned_to: organization) }
          let!(:completed_tasks) { FactoryBot.create_list(:generic_task, 7, :completed, assigned_to: organization) }

          before { allow(organization).to receive(:use_task_pages_api?).and_return(true) }

          it "returns the tasks in the correct tabs" do
            tabs = subject

            # Tasks are serialized at this point so we need to convert integer task IDs to strings.
            expect(tabs[0][:tasks].pluck(:id)).to match_array(unassigned_tasks.map { |t| t.id.to_s })
            expect(tabs[1][:tasks].pluck(:id)).to match_array(on_hold_tasks.map { |t| t.id.to_s })
            expect(tabs[2][:tasks].pluck(:id)).to match_array(completed_tasks.map { |t| t.id.to_s })
          end

          it "displays the correct labels for the tabs" do
            tabs = subject

            expect(tabs[0][:label]).to eq(
              format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, unassigned_tasks.count)
            )
            expect(tabs[1][:label]).to eq(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, on_hold_tasks.count))
            expect(tabs[2][:label]).to eq(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
          end
        end
      end

      context "with an organization that displays regional office in queue table views" do
        before { allow(organization).to receive(:show_regional_office_in_queue?).and_return(true) }

        it "includes the regional column in the list of columns for all tabs" do
          subject.each do |tab|
            expect(tab[:columns]).to include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
          end
        end
      end

      context "when the organization is a VSO" do
        let(:organization) { FactoryBot.create(:vso) }

        it "includes a tab for tracking tasks" do
          expect(subject.length).to eq(4)
          expect(subject.pluck(:name)).to include(Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME)
        end

        it "has the correct shape for each tab hash" do
          subject.each do |tab|
            expect(tab.keys).to match_array(
              [
                :label,
                :name,
                :description,
                :columns,
                :allow_bulk_assign,
                :tasks,
                :task_page_count,
                :total_task_count,
                :task_page_endpoint_base_path
              ]
            )
          end
        end

        context "when the VSO has tracking tasks assigned to it" do
          before { FeatureToggle.enable!(:use_task_pages_api) }
          after { FeatureToggle.disable!(:use_task_pages_api) }

          let!(:tracking_tasks) { FactoryBot.create_list(:track_veteran_task, 5, assigned_to: organization) }

          it "returns the tasks in the tracking tasks tabs" do
            # Tasks are serialized at this point so we need to convert integer task IDs to strings.
            expect(subject[0][:tasks].pluck(:id)).to match_array(tracking_tasks.map { |t| t.id.to_s })
          end
        end
      end
    end
  end
end
