import React from 'react';
import { render, screen } from '@testing-library/react';

import NationalHearingQueueContainer from '../../../../app/queue/nationalHearingQueue/NationalHearingQueueContainer';

describe('NationalHearingQueueContainer', () => {
  const pageTitle = 'National Hearings Scheduling Queue';

  const defaultProps = {
    // Add props here
  };

  const setupComponent = () => {
    return render(<NationalHearingQueueContainer {...defaultProps} />
    );
  };

  it('renders title', () => {
    setupComponent();
    expect(screen.getByText(pageTitle)).toBeInTheDocument();
  });
});
