# frozen_string_literal: true

describe QueueConfig, :postgres do
  describe ".new" do
    let(:arguments) { { assignee: assignee } }

    subject { QueueConfig.new(arguments) }

    context "when object is created with no arguments" do
      let(:arguments) { {} }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a nil organization" do
      let(:assignee) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when object is created with a valid organization" do
      let(:assignee) { create(:organization) }

      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end

    context "when object is created with a valid user" do
      let(:assignee) { create(:user) }

      it "successfully instantiates the object" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe ".to_hash" do
    let(:assignee) { create(:organization) }
    let(:user) { create(:user) }

    subject { QueueConfig.new(assignee: assignee).to_hash }

    describe "shape of the returned hash" do
      it "returns the correct top level keys in the response" do
        expect(subject.keys).to match_array([:table_title, :active_tab, :tasks_per_page, :use_task_pages_api, :tabs])
      end
    end

    describe "title" do
      context "when assigned to an org" do
        it "is formatted as expected" do
          expect(subject[:table_title]).to eq(format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, assignee.name))
        end
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "is formatted as expected" do
          expect(subject[:table_title]).to eq(COPY::USER_QUEUE_PAGE_TABLE_TITLE)
        end
      end
    end

    describe "active_tab" do
      it "is the unassigned tab" do
        expect(subject[:active_tab]).to eq(Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME)
      end

      context "when assigned to a user" do
        let(:assignee) { user }

        it "is the assigned tab" do
          expect(subject[:active_tab]).to eq(Constants.QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME)
        end
      end
    end

    describe "tabs" do
      let(:assignee) { create(:organization) }

      subject { QueueConfig.new(assignee: assignee).to_hash[:tabs] }

      context "with a non-VSO organization assignee" do
        it "does not include a tab for tracking tasks" do
          expect(subject.length).to eq(4)
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
                :contains_legacy_tasks,
                :tasks,
                :task_page_count,
                :total_task_count,
                :task_page_endpoint_base_path,
                :defaultSort
              ]
            )
          end
        end

        it "does not include the regional column in the list of columns for any tab" do
          subject.each do |tab|
            expect(tab[:columns].map { |col| col[:name] })
              .to_not include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
          end
        end

        context "when the organization has assigned tasks" do
          let!(:unassigned_tasks) { create_list(:ama_task, 4, assigned_to: assignee) }
          let!(:assigned_tasks) do
            create_list(:ama_task, 2, parent: create(:ama_task, assigned_to: assignee))
          end
          let!(:on_hold_tasks) do
            create_list(:ama_task, 2, :on_hold, parent: create(:ama_task, assigned_to: assignee))
          end
          let!(:completed_tasks) { create_list(:ama_task, 7, :completed, assigned_to: assignee) }

          it "returns the tasks in the correct tabs" do
            tabs = subject

            # Tasks are serialized at this point so we need to convert integer task IDs to strings.
            expect(tabs[0][:tasks].pluck(:id)).to match_array(unassigned_tasks.map { |t| t.id.to_s })
            expect(tabs[1][:tasks].pluck(:id)).to match_array(assigned_tasks.map { |t| t.id.to_s })
            expect(tabs[2][:tasks].pluck(:id)).to match_array(on_hold_tasks.map { |t| t.id.to_s })
            expect(tabs[3][:tasks].pluck(:id)).to match_array(completed_tasks.map { |t| t.id.to_s })
          end

          it "displays the correct labels for the tabs" do
            tabs = subject

            expect(tabs[0][:label]).to eq(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE)
            expect(tabs[1][:label]).to eq(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE)
            expect(tabs[2][:label]).to eq(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE)
            expect(tabs[3][:label]).to eq(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
          end
        end
      end

      context "with an organization assignee that displays regional office in queue table views" do
        before { allow(assignee).to receive(:show_regional_office_in_queue?).and_return(true) }

        it "includes the regional column in the list of columns for all tabs" do
          subject.each do |tab|
            expect(tab[:columns].map { |col| col[:name] })
              .to include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
          end
        end
      end

      context "when the organization assignee is a VSO" do
        let(:assignee) { create(:vso) }

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
                :contains_legacy_tasks,
                :tasks,
                :task_page_count,
                :total_task_count,
                :task_page_endpoint_base_path,
                :defaultSort
              ]
            )
          end
        end

        context "when the VSO has tracking tasks assigned to it" do
          let!(:tracking_tasks) { create_list(:track_veteran_task, 5, assigned_to: assignee) }

          it "returns the tasks in the tracking tasks tabs" do
            # Tasks are serialized at this point so we need to convert integer task IDs to strings.
            expect(subject[0][:tasks].pluck(:id)).to match_array(tracking_tasks.map { |t| t.id.to_s })
          end
        end
      end

      context "with a user assignee" do
        let(:assignee) { create(:user) }
        let(:task_count) { TaskPager::TASKS_PER_PAGE + 1 }
        let!(:active_tasks) { create_list(:ama_task, task_count, assigned_to: assignee) }
        let!(:on_hold_tasks) { create_list(:ama_task, task_count, :on_hold, assigned_to: assignee) }
        let!(:closed_tasks) { create_list(:ama_task, task_count, :completed, assigned_to: assignee) }

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
                :contains_legacy_tasks,
                :tasks,
                :task_page_count,
                :total_task_count,
                :task_page_endpoint_base_path,
                :defaultSort
              ]
            )
          end
        end

        it "does not include the regional column in the list of columns for any tab" do
          subject.each do |tab|
            expect(tab[:columns]).to_not include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
          end
        end

        it "displays the correct labels for the tabs" do
          tabs = subject

          expect(tabs[0][:label]).to eq(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE)
          expect(tabs[1][:label]).to eq(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE)
          expect(tabs[2][:label]).to eq(COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE)
        end

        it "displays the correct descriptions for the tabs" do
          tabs = subject

          expect(tabs[0][:description]).to eq(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION)
          expect(tabs[1][:description]).to eq(COPY::USER_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION)
          expect(tabs[2][:description]).to eq(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION)
        end

        context "when the user does not use the task pages API" do
          it "returns all tasks rather than paged tasks" do
            tabs = subject

            # Ensure all tasks have been returned
            expect(tabs.all? { |tab| tab[:tasks].count.eql? task_count }).to be true
            expect(tabs.all? { |tab| tab[:task_page_count].eql? 1 }).to be true
            expect(tabs.all? { |tab| tab[:total_task_count].eql? task_count }).to be true
            # Tasks are serialized at this point so we need to convert integer task IDs to strings.
            expect(tabs[0][:tasks].pluck(:id)).to match_array(active_tasks.map(&:id).map(&:to_s))
            expect(tabs[1][:tasks].pluck(:id)).to match_array(on_hold_tasks.map(&:id).map(&:to_s))
            expect(tabs[2][:tasks].pluck(:id)).to match_array(closed_tasks.map(&:id).map(&:to_s))
          end
        end

        context "when the user uses the task pages API" do
          before { FeatureToggle.enable!(:user_queue_pagination, users: [assignee.css_id]) }
          after { FeatureToggle.disable!(:user_queue_pagination, users: [assignee.css_id]) }

          it "returns the tasks in the correct tabs, but only 15" do
            tabs = subject

            expect(tabs.all? { |tab| tab[:tasks].count.eql? TaskPager::TASKS_PER_PAGE }).to be true
            expect(tabs.all? { |tab| tab[:task_page_count].eql? 2 }).to be true
            expect(tabs.all? { |tab| tab[:total_task_count].eql? task_count }).to be true
            expect(tabs[0][:tasks].pluck(:id).all? { |id| active_tasks.map(&:id).map(&:to_s).include?(id) }).to be true
            expect(tabs[1][:tasks].pluck(:id).all? { |id| on_hold_tasks.map(&:id).map(&:to_s).include?(id) }).to be true
            expect(tabs[2][:tasks].pluck(:id).all? { |id| closed_tasks.map(&:id).map(&:to_s).include?(id) }).to be true
          end
        end
      end
    end
  end
end
