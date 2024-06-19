import React from 'react';
import { render, screen } from '@testing-library/react';
import { HearingEmail } from 'app/hearings/components/details/HearingEmail';
import COPY from 'COPY';

const email = '123@gmail.com';
const emailType = 'appellantTz';
const label = 'Appellant Email';
const helperText = "This email address will be used to send notifications for this hearing only."

describe('HearingEmails', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const {asFragment } = render(
      <HearingEmail label={label} emailType={emailType} email={email} />
    );

    // Assertions
    const textField = screen.getByRole('textbox');
    expect(textField).toBeInTheDocument();

    const emailHelper = screen.getByText(COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT);
    expect(emailHelper).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Respects required prop', () => {
    // Run the test
    const {asFragment } = render(
      <HearingEmail label={label} emailType={emailType} email={email} required />
    );

    // Assertions
    const appellantEmail = screen.getByText('Appellant Email');
    const required = screen.getByText('Required');
    expect(appellantEmail).toBeInTheDocument();
    expect(required).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not allow editing when ReadOnly', () => {
    // Run the test
    const {asFragment } = render(
      <HearingEmail label={label} emailType={emailType} email={email} readOnly />
    );

    // Assertions
    expect(screen.queryByRole('textbox')).toBeNull();
    expect(screen.queryByText(helperText)).toBeNull()
    expect(screen.queryByText(label)).toBeInTheDocument();
    expect(screen.queryByText(email)).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not show required when ReadOnly', () => {
    // Run the test
    const {asFragment } = render(
      <HearingEmail label={label} emailType={emailType} email={email} disabled required />
    );

    // Assertions
    expect(screen.queryByText('Required')).toBeNull();

    expect(asFragment()).toMatchSnapshot();
  });
})
;
