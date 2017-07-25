describe JobRavenReporterMiddleware do
  before do
    @middleware = JobRavenReporterMiddleware.new
    @yield_called = false
    @raven_called = false
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end

  context ".call" do
    let(:call) { 
      @middleware.call(nil, @msg, :default) { 
        @yield_called = true 
        raise RuntimeError.new("tsk tsk tsk, you messed up!")
      } 
    }

    it "yields properly, forwards errors to Raven and re-raises the exception" do
      expect(@yield_called).to be_falsey
      expect(@raven_called).to be_falsey
      expect { call }.to raise_error(RuntimeError)
      expect(@yield_called).to be_truthy
      expect(@raven_called).to be_truthy
    end
  end
end
