import React from 'react';
import { render, screen } from '@testing-library/react';
import { DailyDocketGuestLinkSection } from '../../../../../app/hearings/components/dailyDocket/DailyDocketGuestLinkSection';

describe('DailyDocketGuestLinkSection', () => {
  const linkInfo = {
    link1: {
      guestLink: 'https://example.com/guestLink1?pin=1234',
      guestPin: '1234',
      alias: 'Room 1',
      type: 'PexipConferenceLink',
    },
    link2: {
      guestLink: 'https://example.com/guestLink2?meetingID=123456789',
      guestPin: '56789',
      alias: 'Room 2',
      type: 'WebexConferenceLink',
    },
  };

  it('renders the guest link information', async () => {
    render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    const link1Alias = screen.getAllByText('Conference Room:');
    const link1Pin = await screen.findByText('1234#');
    const link1CopyButtons = screen.getAllByRole('button', {
      name: 'Copy Guest Link',
    });

    const link2Alias = screen.getAllByText('Conference Room:');
    const link2Pin = await screen.findByText('56789#');
    const link2CopyButton = screen.getAllByRole('button', {
      name: 'Copy Guest Link',
    });

    expect(link1Alias[0]).toBeInTheDocument();
    expect(link1Pin).toBeInTheDocument();
    expect(link1CopyButtons[0]).toBeInTheDocument();

    expect(link2Alias[1]).toBeInTheDocument();
    expect(link2Pin).toBeInTheDocument();
    expect(link2CopyButton[1]).toBeInTheDocument();
  });
});
