import React from 'react';
import { mount } from 'enzyme';

import { VirtualHearingFields } from 'app/hearings/components/VirtualHearings/Fields';
import { virtualHearing } from 'test/data/hearings';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import { VirtualHearingEmail } from 'app/hearings/components/VirtualHearings/Emails';

describe('Fields', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const fields = mount(
      <VirtualHearingFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Central"
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    // Emails
    expect(fields.find(VirtualHearingEmail)).toHaveLength(2);
    expect(fields.find(VirtualHearingEmail).first().
      prop('email')).toEqual(virtualHearing.virtualHearing.appellantEmail);
    expect(fields.find(VirtualHearingEmail).first().
      prop('label')).toEqual('Veteran Email');
    expect(fields.find(VirtualHearingEmail).at(1).
      prop('email')).toEqual(virtualHearing.virtualHearing.representativeEmail);

    // Timezones
    expect(fields.find(Timezone)).toHaveLength(2);
    expect(fields.find(Timezone).first().
      prop('value')).toEqual(virtualHearing.virtualHearing.appellantTz);
    expect(fields.find(Timezone).at(1).
      prop('value')).toEqual(virtualHearing.virtualHearing.representativeTz);

    // Other components
    expect(fields.find('.cf-help-divider')).toHaveLength(1);
    expect(fields).toMatchSnapshot();
  });

  test('Does not display timezone or divider for Video hearings', () => {
    // Run the test
    const fields = mount(
      <VirtualHearingFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Video"
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    // Emails
    expect(fields.find(VirtualHearingEmail)).toHaveLength(2);
    expect(fields.find(VirtualHearingEmail).first().
      prop('email')).toEqual(virtualHearing.virtualHearing.appellantEmail);
    expect(fields.find(VirtualHearingEmail).first().
      prop('label')).toEqual('Veteran Email');
    expect(fields.find(VirtualHearingEmail).at(1).
      prop('email')).toEqual(virtualHearing.virtualHearing.representativeEmail);

    // Timezones
    expect(fields.find(Timezone)).toHaveLength(0);

    // Other components
    expect(fields.find('.cf-help-divider')).toHaveLength(0);
    expect(fields).toMatchSnapshot();
  });
})
;
