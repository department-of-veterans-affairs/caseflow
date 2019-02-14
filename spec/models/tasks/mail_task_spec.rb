describe MailTask do
  let(:user) { FactoryBot.create(:user) }
  let(:mail_team) { MailTeam.singleton }
  let(:root_task) { FactoryBot.create(:root_task) }
  before do
    OrganizationsUser.add_user_to_organization(user, mail_team)
  end

  describe ".create_from_params" do
    # Use AodMotionMailTask because we do create subclasses of MailTask, never MailTask itself.
    let(:task_class) { AodMotionMailTask }
    let(:params) { { appeal: root_task.appeal, parent_id: root_task_id, type: task_class.name } }
    let(:root_task_id) { root_task.id }

    context "when no root_task exists for appeal" do
      let(:root_task_id) { nil }

      it "throws an error" do
        expect { task_class.create_from_params(params, user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when root_task exists for appeal" do
      it "creates AodMotionMailTask assigned to MailTeam and AodTeam" do
        expect { task_class.create_from_params(params, user) }.to_not raise_error
        expect(root_task.children.length).to eq(1)

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(task_class)
        expect(mail_task.assigned_to).to eq(mail_team)
        expect(mail_task.children.length).to eq(1)

        child_task = mail_task.children[0]
        expect(child_task.class).to eq(task_class)
        expect(child_task.assigned_to).to eq(AodTeam.singleton)
        expect(child_task.children.length).to eq(0)
      end
    end

    context "when child task creation fails" do
      before do
        allow(task_class).to receive(:create_child_task).and_raise(StandardError)
      end

      it "should not create any mail tasks" do
        expect { task_class.create_from_params(params, user) }.to raise_error(StandardError)
        expect(root_task.children.length).to eq(0)
      end
    end

    context "when user is not a member of the mail team" do
      let(:non_mail_user) { FactoryBot.create(:user) }

      it "should raise an error" do
        expect { task_class.create_from_params(params, non_mail_user) }.to raise_error(
          Caseflow::Error::ActionForbiddenError
        )
      end
    end
  end

  describe ".outstanding_cavc_tasks?" do
    it "should always return false since we do not yet have CAVC tasks" do
      expect(MailTask.outstanding_cavc_tasks?(root_task)).to eq(false)
    end
  end

  describe ".pending_hearing_task?" do
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }

    subject { MailTask.pending_hearing_task?(root_task) }

    context "when the task's appeal is in the hearing docket" do
      let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
      it "should be true" do
        expect(subject).to eq(true)
      end
    end

    context "when the task's appeal is not in the hearing docket" do
      let(:appeal) { FactoryBot.create(:appeal) }
      it "should be false" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".case_active?" do
    subject { MailTask.case_active?(root_task) }

    context "when the appeal is active" do
      before { allow_any_instance_of(Appeal).to receive(:active?).and_return(true) }

      it "should return true" do
        expect(subject).to eq(true)
      end
    end

    context "when the appeal is not active" do
      before { allow_any_instance_of(Appeal).to receive(:active?).and_return(false) }

      it "should return false" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".most_recent_active_task_assignee" do
    subject { MailTask.most_recent_active_task_assignee(root_task) }

    context "when the only task for an appeal is the root task" do
      it "should return nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when all individually assigned tasks are complete" do
      before do
        FactoryBot.create_list(:generic_task, 4, :completed, appeal: root_task.appeal)
      end

      it "should return nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when the most recent active task is assigned to an organization" do
      let(:user) { FactoryBot.create(:user) }
      let(:user_task) { FactoryBot.create(:generic_task, appeal: root_task.appeal, assigned_to: user) }

      before do
        FactoryBot.create(
          :generic_task,
          appeal: root_task.appeal,
          assigned_to: FactoryBot.create(:organization),
          parent: user_task
        )
      end

      it "should return a user object" do
        expect(subject).to be_a(User)

        user_task = Task.find_by(assigned_to: user)
        expect(user_task.children.count).to eq(1)
        expect(user_task.children.first.assigned_to).to be_a(Organization)
      end
    end

    context "when there are multiple active tasks assigned to individual users" do
      let(:user) { FactoryBot.create(:user) }

      before do
        FactoryBot.create_list(:generic_task, 6, appeal: root_task.appeal)
        FactoryBot.create(:generic_task, appeal: root_task.appeal, assigned_to: user)
      end

      it "should return the user who was assigned the most recently created task" do
        expect(subject).to eq(user)
      end
    end
  end

  describe ".child_task_assignee (routing logic)" do
    let(:mail_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: mail_team) }
    let(:params) { {} }

    subject { task_class.child_task_assignee(mail_task, params) }

    context "for an AddressChangeMailTask" do
      let(:task_class) { AddressChangeMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearing admin branch" do
          expect(subject).to eq(HearingAdmin.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an AodMotionMailTask" do
      let(:task_class) { AodMotionMailTask }

      it "should always route to the AOD team" do
        expect(subject).to eq(AodTeam.singleton)
      end
    end

    context "for an AppealWithdrawalMailTask" do
      let(:task_class) { AppealWithdrawalMailTask }

      it "should always route to the VLJ support staff" do
        expect(subject).to eq(Colocated.singleton)
      end
    end

    context "for a ClearAndUnmistakeableErrorMailTask" do
      let(:task_class) { ClearAndUnmistakeableErrorMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for a CongressionalInterestMailTask" do
      let(:task_class) { CongressionalInterestMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for a ControlledCorrespondenceMailTask" do
      let(:task_class) { ControlledCorrespondenceMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for a DeathCertificateMailTask" do
      let(:task_class) { DeathCertificateMailTask }

      it "should always route to the VLJ support staff" do
        expect(subject).to eq(Colocated.singleton)
      end
    end

    context "for an EvidenceOrArgumentMailTask" do
      let(:task_class) { EvidenceOrArgumentMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearing admin branch" do
          expect(subject).to eq(HearingAdmin.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an ExtensionRequestMailTask" do
      let(:task_class) { ExtensionRequestMailTask }

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an FoiaRequestMailTask" do
      let(:task_class) { FoiaRequestMailTask }

      it "should always route to the Privacy team" do
        expect(subject).to eq(PrivacyTeam.singleton)
      end
    end

    context "for an HearingRelatedMailTask" do
      let(:task_class) { HearingRelatedMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearing admin branch" do
          expect(subject).to eq(HearingAdmin.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an OtherMotionMailTask" do
      let(:task_class) { OtherMotionMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for an PowerOfAttorneyRelatedMailTask" do
      let(:task_class) { PowerOfAttorneyRelatedMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearing admin branch" do
          expect(subject).to eq(HearingAdmin.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an PrivacyActRequestMailTask" do
      let(:task_class) { PrivacyActRequestMailTask }

      it "should always route to the Privacy team" do
        expect(subject).to eq(PrivacyTeam.singleton)
      end
    end

    context "for an PrivacyComplaintMailTask" do
      let(:task_class) { PrivacyComplaintMailTask }

      it "should always route to the Privacy team" do
        expect(subject).to eq(PrivacyTeam.singleton)
      end
    end

    context "for an ReturnedUndeliverableCorrespondenceMailTask" do
      let(:task_class) { ReturnedUndeliverableCorrespondenceMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearing admin branch" do
          expect(subject).to eq(HearingAdmin.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should route to BVA dispatch" do
          expect(subject).to eq(BvaDispatch.singleton)
        end
      end

      context "when the appeal is active, does not have any hearing tasks, but does have individually assigned tasks" do
        let(:user) { FactoryBot.create(:user) }
        before do
          FactoryBot.create_list(:generic_task, 4, appeal: root_task.appeal)
          FactoryBot.create(:generic_task, appeal: root_task.appeal, assigned_to: user)
        end

        it "should route to the user who is assigned the most recently created active task" do
          expect(subject).to eq(user)
        end
      end

      context "when the appeal is active but has no individually assigned tasks" do
        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end
    end

    context "for an ReconsiderationMotionMailTask" do
      let(:task_class) { ReconsiderationMotionMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for an StatusInquiryMailTask" do
      let(:task_class) { StatusInquiryMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end

    context "for an VacateMotionMailTask" do
      let(:task_class) { VacateMotionMailTask }

      it "should always route to Lit Support" do
        expect(subject).to eq(LitigationSupport.singleton)
      end
    end
  end
end
