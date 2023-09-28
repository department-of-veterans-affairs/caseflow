import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';
// eslint-disable-next-line max-len
import { DailyDocketGuestLinkSection } from '../../../../../app/hearings/components/dailyDocket/DailyDocketGuestLinkSection';

describe('DailyDocketGuestLinkSection', () => {

  const linkInfo = {
    alias: 'BVA0000001@caseflow.va.gov',
    guestLink: 'https://example.va.gov/sample/?conference=BVA0000001@example.va.gov&pin=3998472&callType=video',
    guestPin: '3998472',
  };

  it('renders correctly for hearing admins and hearing management users', () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non hearing admins and hearing management users', () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders conference room correctly', () => {
    render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    expect(screen.getByRole('heading', { name: 'Conference Room: BVA0000001@caseflow.va.gov' })).toBeTruthy();
  });

  it('renders guest pin correctly', () => {
    render(<DailyDocketGuestLinkSection linkInfo={linkInfo} />);

    expect(screen.getByRole('heading', { name: 'PIN: 3998472#' })).toBeTruthy();
  });

  it('renders correctly for hearing admins and hearing management users if the hearing date is passed', () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={null} />);

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non hearing admins and hearing management users if the hearing date is passed', () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={null} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing if the hearing date is passed', async () => {
    const { container } = render(<DailyDocketGuestLinkSection linkInfo={null} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders conference room correctly if the hearing date is passed', () => {
    render(<DailyDocketGuestLinkSection linkInfo={null} />);

    expect(screen.getByRole('heading', { name: 'Conference Room: N/A' })).toBeTruthy();
  });

  it('renders guest pin correctly if the hearing date is passed', () => {
    render(<DailyDocketGuestLinkSection linkInfo={null} />);

    expect(screen.getByRole('heading', { name: 'PIN: N/A' })).toBeTruthy();
  });
});
