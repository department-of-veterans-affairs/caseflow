# frozen_string_literal: true

describe DBService do
  context ".request" do
    subject do
      DBService.release_db_connections
    end

    context "when feature flag is turned on", db_clean: :truncation do
      def active_record_connections
        ActiveRecord::Base.connection_pool.connections.count { |c| c.in_use? && c.owner.alive? }
      end

      def vacols_connections
        VACOLS::Record.connection_pool.connections.count { |c| c.in_use? && c.owner.alive? }
      end

      before do
        FeatureToggle.enable!(:release_db_connections)
      end

      context "when connections have been grabbed" do
        before do
          # Force grabbing connections
          ActiveRecord::Base.connection
          VACOLS::Record.connection
        end

        it "when not in a transaction, connections are released and can be re-grabbed" do
          expect(active_record_connections).to eq(1)
          expect(vacols_connections).to eq(1)
          subject
          expect(active_record_connections).to eq(0)
          expect(vacols_connections).to eq(0)
          ActiveRecord::Base.connection
          VACOLS::Record.connection
          expect(active_record_connections).to eq(1)
          expect(vacols_connections).to eq(1)
        end

        it "when in an ActiveRecord transaction, ActiveRecord connections are not released" do
          ActiveRecord::Base.connection.transaction do
            expect(active_record_connections).to eq(1)
            expect(vacols_connections).to eq(1)
            subject
            expect(active_record_connections).to eq(1)
            expect(vacols_connections).to eq(0)
          end
        end

        it "when in a VACOLS transaction, connections are not released" do
          VACOLS::Record.connection.transaction do
            expect(active_record_connections).to eq(1)
            expect(vacols_connections).to eq(1)
            subject
            expect(active_record_connections).to eq(0)
            expect(vacols_connections).to eq(1)
          end
        end
      end

      context "when connections are not grabbed" do
        before do
          VACOLS::Record.connection_pool.release_connection
          ActiveRecord::Base.connection_pool.release_connection
          allow(VACOLS::Record).to receive(:connection).and_call_original
          allow(ActiveRecord::Base).to receive(:connection).and_call_original
        end

        it "does not acquire connection in check for transactions" do
          subject
          expect(VACOLS::Record).to_not have_received(:connection)
          expect(ActiveRecord::Base).to_not have_received(:connection)
        end
      end
    end

    context "when feature flag is turned off" do
      before do
        FeatureToggle.disable!(:release_db_connections)
        allow(VACOLS::Record).to receive(:connection).and_call_original
        allow(ActiveRecord::Base).to receive(:connection).and_call_original
      end

      it "doesn't do anything" do
        subject
        expect(VACOLS::Record).to_not have_received(:connection)
        expect(ActiveRecord::Base).to_not have_received(:connection)
      end
    end
  end
end
