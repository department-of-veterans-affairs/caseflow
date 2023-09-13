import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';
// eslint-disable-next-line max-len
import { WebexDailyDocketGuestLink } from '../../../../../app/hearings/components/dailyDocket/WebexDailyDocketGuestLink';

describe('WebexDailyDocketGuestLink', () => {
  const linkInfo = {
    alias: 'BVA0000001@caseflow.va.gov',
    guestLink:
      'https://example.va.gov/sample/?conference=BVA0000001@example.va.gov&pin=3998472&callType=video',
    guestPin: '3998472',
  };

  it('renders correctly for hearing admins and hearing management users', () => {
    const { container } = render(
      <WebexDailyDocketGuestLink linkInfo={linkInfo} />
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non hearing admins and hearing management users', () => {
    const { container } = render(
      <WebexDailyDocketGuestLink linkInfo={linkInfo} />
    );

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(
      <WebexDailyDocketGuestLink linkInfo={linkInfo} />
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders conference room correctly', () => {
    render(<WebexDailyDocketGuestLink linkInfo={linkInfo} />);

    expect(
      screen.getByRole('heading', {
        name: 'Conference Room: BVA0000001@caseflow.va.gov',
      })
    ).toBeTruthy();
  });

  it('renders guest pin correctly', () => {
    render(<WebexDailyDocketGuestLink linkInfo={linkInfo} />);

    expect(screen.getByRole('heading', { name: 'PIN: 3998472#' })).toBeTruthy();
  });
});
