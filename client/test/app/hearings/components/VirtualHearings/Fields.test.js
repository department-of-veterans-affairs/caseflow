import React from 'react';
import { mount } from 'enzyme';

import { EmailNotificationFields } from 'app/hearings/components/details/EmailNotificationFields';
import { defaultHearing as hearing } from 'test/data/hearings';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import { HearingEmail } from 'app/hearings/components/details/HearingEmail';

describe('Fields', () => {
  const expectations = (fields) => {
    // Emails
    expect(fields.find(HearingEmail)).toHaveLength(2);
    expect(fields.find(HearingEmail).first().
      prop('email')).toEqual(hearing.appellantEmailAddress);
    expect(fields.find(HearingEmail).first().
      prop('label')).toEqual('Veteran Email');
    expect(fields.find(HearingEmail).at(1).
      prop('email')).toEqual(hearing.representativeEmailAddress);

    // Timezones
    expect(fields.find(Timezone)).toHaveLength(2);
    expect(fields.find(Timezone).first().
      prop('value')).toEqual(hearing.appellantTz);
    expect(fields.find(Timezone).at(1).
      prop('value')).toEqual(hearing.representativeTz);

    // Other components
    expect(fields.find('.cf-help-divider')).toHaveLength(1);
    expect(fields).toMatchSnapshot();
  };

  test('Display timezone and divider for Central', () => {
    // Run the test
    const fields = mount(
      <EmailNotificationFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Central"
        hearing={hearing}
      />
    );

    expectations(fields);
  });

  test('Display timezone and divider for Video', () => {
    // Run the test
    const fields = mount(
      <EmailNotificationFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Video"
        hearing={hearing}
      />
    );

    expectations(fields);
  });
});
