describe BvaDispatchTask do
  before { FeatureToggle.enable!(:test_facols) }
  after { FeatureToggle.disable!(:test_facols) }

  describe ".create_and_assign" do
    context "when no root_task passed as argument" do
      it "throws an error" do
        expect { BvaDispatchTask.create_and_assign(nil) }.to raise_error(NoMethodError)
      end
    end

    context "when valid root_task passed as argument" do
      let(:root_task) { FactoryBot.create(:root_task) }
      it "should create a BvaDispatchTask assigned to a User with a parent task assigned to the BvaDispatch org" do
        task = BvaDispatchTask.create_and_assign(root_task)
        expect(task.assigned_to.class).to eq(User)
        expect(task.parent.assigned_to.class).to eq(BvaDispatch)
      end
    end
  end
end
