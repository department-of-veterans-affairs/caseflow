import React from 'react';
import { mount } from 'enzyme';

import { HearingTime } from 'app/hearings/components/VirtualHearings/HearingTime';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import TIMEZONES from 'constants/TIMEZONES';

const [timezoneLabel] = Object.keys(TIMEZONES).filter((zone) => TIMEZONES[zone] === COMMON_TIMEZONES[0]);

describe('HearingTime', () => {
  // Ignore warnings about SearchableDropdown
  jest.spyOn(console, 'error').mockReturnValue();

  test('Matches snapshot with default props', () => {
    // Run the test
    const hearingTime = mount(<HearingTime value={HEARING_TIME_OPTIONS[0].value} />);

    // Assertions
    expect(
      hearingTime.
        find('#react-select-2--value-item').
        first().
        text()
    ).toContain(timezoneLabel);
  });
});
