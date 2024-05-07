import React from 'react';
import { TranscriptionFileDispatchPage } from '../../../../app/hearings/components/TranscriptionFileDispatchPage';
import { screen, render } from '@testing-library/react';

const setup = () => render(<TranscriptionFileDispatchPage />);

describe('TranscriptionFileDispatch', () => {
  it('has title', () => {
    setup();

    expect(screen.getByText('Transcription file dispatch')).toBeTruthy();
  });

  it('has switch views dropdown', () => {
    setup();

    expect(screen.getByText('Switch views')).toBeTruthy();
  });

  it('has the correct tabs', () => {
    const { container } = setup();
    const tabs = container.querySelectorAll('.cf-tab');

    expect(tabs).toHaveLength(4);
    expect(tabs[0].textContent).toBe('Unassigned');
    expect(tabs[1].textContent).toBe('Assigned');
    expect(tabs[2].textContent).toBe('Completed');
    expect(tabs[3].textContent).toBe('All transcription');
  });
});
