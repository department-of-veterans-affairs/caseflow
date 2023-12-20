import React from 'react';
import { shallow, mount } from 'enzyme';

import { HearingEmail } from 'app/hearings/components/details/HearingEmail';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { HelperText } from 'app/hearings/components/VirtualHearings/HelperText';
import COPY from 'COPY';
import TextField from 'app/components/TextField';

const email = '123@gmail.com';
const emailType = 'appellantTz';
const label = 'Appellant Email';

describe('HearingEmails', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const emails = shallow(
      <HearingEmail label={label} emailType={emailType} email={email} />
    );

    // Assertions
    expect(emails.find(TextField)).toHaveLength(1);
    expect(emails.find(HelperText).prop('label')).toEqual(COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT);
    expect(emails).toMatchSnapshot();
  });

  test('Respects required prop', () => {
    // Run the test
    const emails = mount(
      <HearingEmail label={label} emailType={emailType} email={email} required />
    );

    // Assertions
    expect(emails.find('.cf-required')).toHaveLength(1);
    expect(emails).toMatchSnapshot();
  });

  test('Does not allow editing when ReadOnly', () => {
    // Run the test
    const emails = shallow(
      <HearingEmail label={label} emailType={emailType} email={email} readOnly />
    );

    // Assertions
    expect(emails.find(TextField)).toHaveLength(0);
    expect(emails.find(HelperText)).toHaveLength(0);
    expect(emails.find(ReadOnly).prop('label')).toEqual(label);
    expect(emails.find(ReadOnly).prop('text')).toEqual(email);
    expect(emails).toMatchSnapshot();
  });

  test('Does not show required when ReadOnly', () => {
    // Run the test
    const emails = mount(
      <HearingEmail label={label} emailType={emailType} email={email} disabled required />
    );

    // Assertions
    expect(emails.find('.cf-required')).toHaveLength(0);
    expect(emails).toMatchSnapshot();
  });
})
;
