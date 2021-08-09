# frozen_string_literal: true

require "query_subscriber"

describe BelongsToPolymorphicAppealConcern do
  let!(:decision_doc) { create(:decision_document, appeal: create(:appeal, :with_decision_issue, :at_bva_dispatch)) }
  let!(:legacy_decision_doc) { create(:decision_document, appeal: create(:legacy_appeal)) }

  context "concern is included in DecisionDocument" do
    it "`ama_appeal` returns the AMA appeal" do
      expect(decision_doc.ama_appeal).to eq decision_doc.appeal
    end

    it "`legacy_appeal` returns the legacy appeal" do
      expect(legacy_decision_doc.legacy_appeal).to eq legacy_decision_doc.appeal
    end

    it "`tasks` returns the AMA appeal's tasks" do
      expect(decision_doc.tasks).to match_array decision_doc.appeal.tasks
    end

    it "`tasks` returns the legacy appeal's tasks" do
      expect(legacy_decision_doc.tasks).to match_array legacy_decision_doc.appeal.tasks
    end

    it "scope `ama` returns AMA-associated DecisionDocuments" do
      expect(DecisionDocument.ama.first).to eq decision_doc
    end

    it "scope `legacy` returns legacy-associated DecisionDocuments" do
      expect(DecisionDocument.legacy.first).to eq legacy_decision_doc
    end

    context "when `has_many ama_decision_issues through: :ama_appeal` is defined" do
      subject { decision_doc.ama_decision_issues }
      it "returns the correct decision_issues" do
        expect(subject.count).to eq 2
        expect(subject).to eq decision_doc.appeal.decision_issues
      end

      it "decision_issues returns the correct decision_documents" do
        expect(decision_doc.ama_decision_issues.first.ama_decision_documents).to eq [decision_doc]
      end

      context "when querying for decision_issues for all DecisionDocuments" do
        subject { DecisionDocument.ama.includes(:ama_decision_issues) }
        let(:query_subscriber) { QuerySubscriber.new }
        before do
          4.times { create(:decision_document, appeal: create(:appeal, :with_decision_issue)) }
        end

        it "queries efficiently" do
          query_subscriber.track do
            # To query for columns in both tables, must query using SQL (#2) or use pluck_to_hash (#3)
            query = DecisionDocument.ama.includes(:ama_decision_issues)
              .references(:decision_issues).references(:decision_documents)

            # 1. Querying via Rails returns only DecisionDocument attributes
            json_result = query.as_json
            expect(json_result.size).to eq 5

            # 2. Querying using SQL produces incomprehensible numerical column names
            sql_result = ActiveRecord::Base.connection.exec_query(query.to_sql)
            expect(sql_result.to_hash.size).to eq 10

            # 3. Querying using pluck_to_hash works but must specify all columns
            fields = DecisionDocument.column_names.map { |n| DecisionDocument.table_name + "." + n } +
                     DecisionIssue.column_names.map { |n| DecisionIssue.table_name + "." + n }
            hash_result = query.pluck_to_hash(*fields.uniq) # sensible column names as long as they're unique
            expect(hash_result.size).to eq 10
            expect(hash_result.sample.size).to eq fields.size # ensure result has all requested fields
          end

          # 1 efficient SELECT query for each trial above
          expect(query_subscriber.queries.count).to eq 3
          expect(query_subscriber.select_queries.size).to eq 3
        end
      end
    end
  end

  context "concern is included in Task" do
    let(:task) { decision_doc.appeal.tasks.sample }

    before { Colocated.singleton.add_user(create(:user)) }
    let!(:legacy_task) { create(:colocated_task, appeal: legacy_decision_doc.appeal) }

    it "`ama_appeal` returns the AMA appeal" do
      expect(task.ama_appeal).to eq decision_doc.appeal
    end

    it "`legacy_appeal` returns the legacy appeal" do
      expect(legacy_task.legacy_appeal).to eq legacy_decision_doc.appeal
    end

    it "`tasks` returns the AMA appeal's tasks" do
      expect(task.tasks).to match_array decision_doc.appeal.tasks
    end

    it "`tasks` returns the legacy appeal's tasks" do
      expect(legacy_task.tasks).to match_array legacy_decision_doc.appeal.tasks
    end

    it "scope `ama` returns AMA-associated Tasks" do
      expect(Task.ama).to match_array Task.where(appeal_type: "Appeal")
    end

    it "scope `legacy` returns legacy-associated Tasks" do
      expect(Task.legacy).to match_array Task.where(appeal_type: "LegacyAppeal")
    end

    context "when querying for appeal data for all Tasks" do
      let(:query_subscriber) { QuerySubscriber.new }
      before { 4.times { create(:appeal, :with_decision_issue, :at_bva_dispatch) } }

      it "queries efficiently" do
        appeal_uuids = Appeal.pluck(:uuid)
        legacy_appeal_vacols_ids = LegacyAppeal.pluck(:vacols_id)

        query_subscriber.track do
          # Addresses 'Cannot eagerly load the polymorphic association' error
          # when trying to call `Task.includes(:appeal).pluck("appeals.docket_type")` or even
          # `Task.includes(:appeal).references(:appeals).where(tasks: {appeal_type: "Appeal"}).pluck("appeals.uuid")`
          expect(Task.ama.includes(:ama_appeal).pluck("appeals.uuid").uniq)
            .to match_array appeal_uuids
          expect(Task.legacy.includes(:legacy_appeal).pluck("legacy_appeals.vacols_id").uniq)
            .to match_array legacy_appeal_vacols_ids
        end

        # 1 efficient SELECT query for each trial above
        expect(query_subscriber.queries.count).to eq 2
        expect(query_subscriber.select_queries.size).to eq 2
      end
    end
  end
end
