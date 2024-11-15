import React from 'react';
import { render, screen } from '@testing-library/react';
import BandwidthAlert from '../../../app/reader/BandwidthAlert';

// variables being defined are in mbps
const bandwidthUnderThreshold = 1.0;
const bandwidthOverThreshold = 2.0;

const mockNavigationConnection = (downlink) => {
  Object.defineProperty(global.navigator, 'connection', {
    value: {
      downlink,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn()
    },
    writable: true
  });
};

describe('BandwidthAlert', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should render warning alert if downlink is below 1.5', () => {
    mockNavigationConnection(bandwidthUnderThreshold);

    render(<BandwidthAlert />);

    const alertMessage = screen.getByText(/You may experience slower downloading times/i);

    expect(alertMessage).toBeInTheDocument();
  });

  it('should not render alert if downlink is above 1.5', () => {
    mockNavigationConnection(bandwidthOverThreshold);

    render(<BandwidthAlert />);

    const alertMessage = screen.queryByText(/You may experience slower downloading times/i);

    expect(alertMessage).not.toBeInTheDocument();
  });
});
