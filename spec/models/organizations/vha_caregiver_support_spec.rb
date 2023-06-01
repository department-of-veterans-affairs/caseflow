# frozen_string_literal: true

describe VhaCaregiverSupport, :postgres do
  context "with no VhaCaregiverSupport organization defined" do
    describe ".singleton" do
      subject { VhaCaregiverSupport.singleton }

      it "when called creates an instance of the organization" do
        expect(VhaCaregiverSupport.count).to eq 0

        subject

        expect(VhaCaregiverSupport.count).to eq 1
      end
    end
  end

  context "with a VhaCaregiverSupport organization previously created" do
    let(:vha_csp) do
      VhaCaregiverSupport.create(name: "VHA Caregiver Support Program", url: "vha-csp")
    end

    describe ".singleton" do
      it "VhaCaregiverSupport class has singleton class method defined
      for providing singleton-like behavior" do
        expect(VhaCaregiverSupport.respond_to?(:singleton)).to eq true
      end

      describe ".create!" do
        it "organization that was created has expected name" do
          expect(vha_csp.name).to eq("VHA Caregiver Support Program")
        end

        it "organization that was created has expected url" do
          expect(vha_csp.url).to eq("vha-csp")
        end
      end

      describe ".queue_tabs" do
        it "returns the expected tabs for use in the VHA CSP organization's queue" do
          expect(vha_csp.queue_tabs).to match_array(
            [
              VhaCaregiverSupportUnassignedTasksTab,
              VhaCaregiverSupportInProgressTasksTab,
              VhaCaregiverSupportCompletedTasksTab
            ]
          )
        end
      end

      describe ".can_receive_task?" do
        let(:appeal) { create(:appeal) }
        let(:task) { create(:task, appeal: appeal) }

        # This comes into play for any task with the "ASSIGN_TO_TEAM" task action
        it "returns false because VHA CSP office cannot have tasks manually assigned to them" do
          expect(vha_csp.can_receive_task?(task)).to eq(false)
        end
      end

      describe ".COLUMN_NAMES" do
        it "VHA CSP organization queue tabs have 8 columns by default" do
          expect(VhaCaregiverSupport::COLUMN_NAMES.count).to eq 9
        end
      end
    end
  end
end
