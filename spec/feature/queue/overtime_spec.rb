# frozen_string_literal: true

RSpec.feature "Overtime", :all_dbs do
  shared_examples "shows overtime badge" do
    it "shows an overtime badge" do
      expect(page).to have_selector(".cf-overtime-badge")
    end
  end

  shared_examples "does not show overtime badge" do
    it "does not show an overtime badge" do
      expect(page).not_to have_selector(".cf-overtime-badge")
    end
  end

  shared_examples "correctly displays overtime badge for all users" do
    before { visit url }

    it_behaves_like "does not show overtime badge"

    context "when the case has been marked as overtime" do
      let(:overtime) { true }
      context "user is a judge" do
        it_behaves_like "shows overtime badge"
      end

      context "user is an attorney" do
        let(:current_user) { attorney_user }
        it_behaves_like "shows overtime badge"
      end

      context "user is a colocated user" do
        let(:current_user) { colocated_user }
        it_behaves_like "does not show overtime badge"
      end
    end
  end

  let!(:attorney_user) { create(:user).tap { |user| create(:staff, :attorney_role, user: user) } }
  let!(:judge_user) { create(:user).tap { |user| create(:staff, :judge_role, user: user) } }
  let(:colocated_user) { create(:user).tap { |user| create(:staff, :colocated_role, user: user) } }
  let(:current_user) { judge_user }

  let(:overtime) { false }
  let(:work_products) { overtime ? QueueMapper::OVERTIME_WORK_PRODUCTS : QueueMapper::WORK_PRODUCTS }
  let!(:legacy_appeal) do
    create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: create(
        :case,
        :assigned,
        assigner: attorney_user,
        user: judge_user,
        work_product: work_products.keys.first
      )
    )
  end
  let!(:appeal) do
    create(:appeal,
           :at_judge_review,
           veteran: create(:veteran),
           associated_attorney: attorney_user,
           associated_judge: judge_user
          )
  end

  before do
    create(
      :attorney_case_review,
      task_id: AttorneyTask.find_by(appeal: appeal).id,
      reviewing_judge: judge_user,
      attorney: attorney_user,
      overtime: overtime
    )
    User.authenticate!(user: current_user)
    FeatureToggle.enable!(:overtime_revamp)
  end
  after { FeatureToggle.disable!(:overtime_revamp) }

  context "on case details screen" do
    it_behaves_like "correctly displays overtime badge for all users" do
      let(:url) { "/queue/appeals/#{appeal.external_id}" }
    end
    it_behaves_like "correctly displays overtime badge for all users" do
      let(:url) { "/queue/appeals/#{legacy_appeal.external_id}" }
    end
  end

  context "in case search" do
    it_behaves_like "correctly displays overtime badge for all users" do
      let(:url) { "/search?veteran_ids=#{appeal.veteran.id}" }
    end
    it_behaves_like "correctly displays overtime badge for all users" do
      let(:url) { "/search?veteran_ids=#{legacy_appeal.veteran.id}" }
    end
  end

  context "in queue" do
    before { visit "/queue" }

    it_behaves_like "does not show overtime badge"

    context "when the case has been marked as overtime" do
      let(:overtime) { true }
      it "shows an overtime badge for both cases" do
        expect(page.find_all(".cf-overtime-badge").length).to eq 2
      end
    end
  end
end
