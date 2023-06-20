import React from 'react';
import { render } from 'react-dom';
import { act } from 'react-dom/test-utils';
import App from '../../app';

jest.mock('../../app/util/Metrics', () => ({
  storeMetrics: jest.fn(),
}));

describe('App', () => {
  it('should call storeMetrics when window.onerror event occurs', () => {
    // Render the component
    const container = document.createElement('div');
    document.body.appendChild(container);
    act(() => {
      render(<App />, container);
    });

    // Trigger the window.onerror event
    const event = new Event('error');
    window.dispatchEvent(event);

    // Assert that storeMetrics has been called with the expected arguments
    expect(storeMetrics).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        event: expect.any(String),
        source: expect.any(String),
        lineno: expect.any(Number),
        colno: expect.any(Number),
        error: expect.any(Object),
      }),
      expect.objectContaining({
        type: 'error',
        product: 'browser',
        start: expect.any(Number),
        end: expect.any(Number),
        duration: expect.any(Number),
      })
    );
  });
});
