describe IssueMapper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".rename_and_validate_vacols_attrs" do
    let(:issue_attrs) do
      {
        program: "02",
        issue: "18",
        level_2: "03",
        level_3: nil,
        note: "another one"
      }
    end

    subject { IssueMapper.rename_and_validate_vacols_attrs(slogid: "TEST1", action: action, issue_attrs: issue_attrs) }

    context "when action is create" do
      let(:action) { :create }
      let(:expected_result) do
        # level_1 is not passed, level_3 is passed with nil value
        {
          issprog: "02",
          isscode: "18",
          isslev2: "03",
          isslev3: nil,
          issdesc: "another one",
          issaduser: "TEST1",
          issadtime: VacolsHelper.local_time_with_utc_timezone
        }
      end

      context "when codes are valid" do
        it "transforms the hash" do
          allow(IssueRepository).to receive(:find_issue_reference).and_return([OpenStruct.new])
          expect(subject).to eq expected_result
        end
      end

      context "when codes are not valid" do
        it "raises IssueRepository::IssueError" do
          allow(IssueRepository).to receive(:find_issue_reference).and_return([])
          expect { subject }.to raise_error(IssueRepository::IssueError)
        end
      end
    end

    context "when action is update" do
      let(:action) { :update }
      let(:expected_result) do
        # level_1 is not passed, level_3 is passed with nil value
        {
          issprog: "02",
          isscode: "18",
          isslev2: "03",
          isslev3: nil,
          issdesc: "another one",
          issmduser: "TEST1",
          issmdtime: VacolsHelper.local_time_with_utc_timezone
        }
      end

      context "when codes are valid" do
        it "transforms the hash" do
          allow(IssueRepository).to receive(:find_issue_reference).and_return([OpenStruct.new])
          expect(subject).to eq expected_result
        end
      end

      context "when codes are not passed" do
        let(:issue_attrs) { { note: "another one" } }

        let(:expected_result) do
          {
            issdesc: "another one",
            issmduser: "TEST1",
            issmdtime: VacolsHelper.local_time_with_utc_timezone
          }
        end
        it "does not validate code combination" do
          expect(IssueRepository).to_not receive(:find_issue_reference)
          expect(subject).to eq expected_result
        end
      end

      context "when codes are not valid" do
        it "raises IssueRepository::IssueError" do
          allow(IssueRepository).to receive(:find_issue_reference).and_return([])
          expect { subject }.to raise_error(IssueRepository::IssueError)
        end
      end

      context "when empty" do
        let(:action) { :update }
        let(:issue_attrs) { {} }

        it "returns empty hash" do
          expect(subject).to eq({})
        end
      end

      context "when disposition is passed" do
        let(:action) { :update }

        context "when valid disposition" do
          let(:issue_attrs) do
            { disposition: "Withdrawn", disposition_date: VacolsHelper.local_date_with_utc_timezone }
          end
          let(:expected_result) do
            {
              issdc: "9",
              issdcls: VacolsHelper.local_date_with_utc_timezone,
              issmduser: "TEST1",
              issmdtime: VacolsHelper.local_time_with_utc_timezone
            }
          end
          it "transforms the hash" do
            expect(subject).to eq expected_result
          end
        end

        context "when not valid disposition" do
          let(:issue_attrs) do
            { disposition: "Incorrect", disposition_date: VacolsHelper.local_date_with_utc_timezone }
          end

          it "raises IssueRepository::IssueError" do
            expect { subject }.to raise_error(IssueRepository::IssueError)
          end
        end
      end
    end
  end
end
