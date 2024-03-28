import React from 'react';
import { render, screen } from '@testing-library/react';
import { DailyDocketGuestLinkSection } from 'app/hearings/components/dailyDocket/DailyDocketGuestLinkSection';

describe('DailyDocketGuestLinkSection', () => {
  const linkInfo = [
    {
      guestLink: 'https://example.com/guestLink1?pin=123456',
      guestPin: '123456',
      alias: 'Room 1',
      type: 'PexipConferenceLink',
    },
    {
      guestLink: 'https://example.com/guestLink2?meetingID=123456789',
      guestPin: '',
      alias: 'Room 2',
      type: 'WebexConferenceLink',
    },
  ];

  it('renders the guest link information', async () => {
    render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    const link1Alias = await screen.findByText('Room 1');
    const pexipLinkText = await screen.findByText('Pexip Guest link for non-virtual hearings');
    const link1Pin = await screen.findByText('123456#');
    const link1CopyButtons = screen.getAllByRole('button', { name: 'Copy Guest Link' });

    const link2Alias = await screen.findByText('Room 2');
    const webexLinkText = await screen.findByText('Webex Guest link for non-virtual hearings');
    const link2CopyButton = screen.getAllByRole('button', { name: 'Copy Guest Link' });

    expect(pexipLinkText).toBeInTheDocument();
    expect(link1Alias).toBeInTheDocument();
    expect(link1Pin).toBeInTheDocument();
    expect(link1CopyButtons[0]).toBeInTheDocument();

    expect(webexLinkText).toBeInTheDocument();
    expect(link2Alias).toBeInTheDocument();
    expect(link2CopyButton[1]).toBeInTheDocument();
  });
});
