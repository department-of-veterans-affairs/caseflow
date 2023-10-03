import React from 'react';
import { render, screen } from '@testing-library/react';
import { DailyDocketGuestLinkSection } from '../../../../../app/hearings/components/dailyDocket/DailyDocketGuestLinkSection';

describe('DailyDocketGuestLinkSection', () => {
  const linkInfo = {
    link1: {
      guestLink: 'https://example.com/guestLink1?pin=123456',
      guestPin: '123456',
      alias: 'Room 1',
      type: 'PexipConferenceLink',
    },
    link2: {
      guestLink: 'https://example.com/guestLink2?meetingID=123456789',
      guestPin: '567891029',
      alias: 'Room 2',
      type: 'WebexConferenceLink',
    },
  };

  it('renders the guest link information', async () => {
    render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    const link1Alias = await screen.getAllByText('Conference Room:');
    const pexipLinkText = await screen.findByText(
      'Pexip Guest link for non-virtual hearings'
    );
    const link1Pin = await screen.findByText('123456#');
    const link1CopyButtons = screen.getAllByRole('button', {
      name: 'Copy Guest Link',
    });

    const webexLinkText = await screen.findByText(
      'Webex Guest link for non-virtual hearings'
    );
    const link2Alias = await screen.getAllByText('Conference Room:');
    const link2Pin = await screen.findByText('123456789#');
    const link2CopyButton = screen.getAllByRole('button', {
      name: 'Copy Guest Link',
    });

    expect(pexipLinkText).toBeInTheDocument();
    expect(link1Alias[0]).toBeInTheDocument();
    expect(link1Pin).toBeInTheDocument();
    expect(link1CopyButtons[0]).toBeInTheDocument();

    expect(webexLinkText).toBeInTheDocument();
    expect(link2Alias[1]).toBeInTheDocument();
    expect(link2Pin).toBeInTheDocument();
    expect(link2CopyButton[1]).toBeInTheDocument();
  });
});
