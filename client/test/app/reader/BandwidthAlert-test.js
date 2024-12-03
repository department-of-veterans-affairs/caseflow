import React from 'react';
import { render, screen } from '@testing-library/react';
import BandwidthAlert from '../../../app/reader/BandwidthAlert';

describe('BandwidthAlert', () => {

  it('should render warning alert if displayBanner is true', () => {

    render(<BandwidthAlert displayBanner />);

    const alertMessage = screen.getByText(/You may experience slower downloading times/i);

    expect(alertMessage).toBeInTheDocument();
  });

  it('should not render alert if displayBanner is false', () => {
    render(<BandwidthAlert displayBanner={false} />);

    const alertMessage = screen.queryByText(/You may experience slower downloading times/i);

    expect(alertMessage).not.toBeInTheDocument();
  });
});
