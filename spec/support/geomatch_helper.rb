# frozen_string_literal: true

module GeomatchHelper
  # Setups a mock for GeomatchService, and creates an expectation that the GeomatchService
  # will be instantiated.
  def setup_geomatch_service_mock(geomatching_appeal)
    geomatch_service = GeomatchService.new(appeal: geomatching_appeal)
    expect(GeomatchService).to(
      receive(:new)
        .with(appeal: geomatching_appeal)
        .at_least(:once)
        .and_return(geomatch_service)
    )

    yield(geomatch_service)
  end
end
