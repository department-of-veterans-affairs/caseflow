import React from 'react';

import { HearingConversion } from 'app/hearings/components/HearingConversion';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import { userWithJudgeRole, amaHearing, vsoUser, anyUser } from 'test/data';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import { VirtualHearingSection } from 'app/hearings/components/VirtualHearings/Section';
import * as DateUtil from 'app/util/DateUtil';
import { AddressLine } from 'app/hearings/components/details/Address';
import { HearingEmail } from 'app/hearings/components/details/HearingEmail';
import { JudgeDropdown } from 'app/components/DataDropdowns';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import { Checkbox } from '../../../../../client/app/components/Checkbox'
import RadioField from 'app/components/RadioField';
import COPY from '../../../../../client/COPY.json'

const updateSpy = jest.fn();
const defaultTitle = 'Convert to Virtual';
const mockUpdateCheckboxes = jest.fn();

describe('HearingConversion', () => {
  test('Matches snapshot with default props', () => {
    const conversion = mount(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[0]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
      />,
      {
        wrappingComponent: hearingDetailsWrapper(
          userWithJudgeRole,
          amaHearing,
          anyUser
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Assertions
    expect(conversion.find(RadioField)).toHaveLength(0);
    expect(conversion.find(VirtualHearingSection)).toHaveLength(3);
    // Check for Instructional Text for Non-VSO User
    expect(
      conversion.containsMatchingElement(
        <span>
          Email notifications will be sent to the Veteran, POA / Representative, and Veterans Law Judge (VLJ).
        </span>
      )
    ).toBeTruthy();
    expect(
      conversion.
        findWhere((node) => node.prop('label') === 'Hearing Date').
        prop('text')
    ).toEqual(DateUtil.formatDateStr(amaHearing.scheduledFor));
    expect(conversion.find(AddressLine)).toHaveLength(2);
    expect(conversion.find(Timezone)).toHaveLength(2);
    expect(conversion.find(HearingEmail)).toHaveLength(2);
    expect(conversion.find(JudgeDropdown)).toHaveLength(1);

    expect(
      conversion.
        findWhere((node) => node.prop('label') === 'vsoCheckboxes')
    ).toHaveLength(0);
    expect(conversion.find(Checkbox)).toHaveLength(0);
    expect(conversion).toMatchSnapshot();
  });

  test('Displays email fields when hearing type is switched from virtual', () => {
    const conversion = mount(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[1]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
        userVsoEmployee= {false}
      />,
      {
        wrappingComponent: hearingDetailsWrapper(
          userWithJudgeRole,
          amaHearing,
          anyUser
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Assertions
    expect(conversion.find(RadioField)).toHaveLength(1);

    // Ensure the judge dropdown section is hidden
    expect(
      conversion.
        findWhere((node) => node.prop('label') === 'Veterans Law Judge (VLJ)').
        prop('hide')
    ).toEqual(true);

    // Ensure the emails are displayed but not the judge
    expect(conversion.find(Timezone)).toHaveLength(2);
    expect(conversion.find(HearingEmail)).toHaveLength(2);
    expect(conversion.find(JudgeDropdown)).toHaveLength(0);

    expect(conversion).toMatchSnapshot();
  });

  test('When a VSO user converts to virtual, the checkboxes and banner appear on the form', () => {
    const conversion = mount(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[0]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
        userVsoEmployee
      />,
      {
        wrappingComponent: hearingDetailsWrapper(
          amaHearing,
          vsoUser
        ),
        wrappingComponentProps: { store: detailsStore },
      });

    //  expect checkbox div to show
    expect(
      conversion.
        findWhere((node) => node.prop('label') === 'vsoCheckboxes')
    ).toHaveLength(1);

    //  expect both checkboxes to show
    expect(conversion.find(Checkbox)).toHaveLength(2);

    // expect span text to appear
    expect(
      conversion.containsMatchingElement(
        <span>{COPY.CONVERT_HEARING_TYPE_SUBTITLE_3}</span>
      )
    ).toBeTruthy();
  });
});
