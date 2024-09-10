import React from 'react';
// import { zoneName } from 'app/hearings/utils';
import { render } from '@testing-library/react';
import { HearingTimeScheduledInTimezone } from 'app/hearings/components/HearingTimeScheduledInTimezone';
import {
  virtualHearing
} from 'test/data';

// Setup the test constants
const showIssueCount = true;
const showRegionalOfficeName = true;
const showRequestType = true;

describe('HearingTimeScheduleInTimezone', () => {
  test('Display HearingTimeScheduleInTimezone', () => {

    const { container } = render(
      <HearingTimeScheduledInTimezone
        hearing={virtualHearing.virtualHearing}
        showIssueCount = {showIssueCount}
        showRegionalOfficeName = {showRegionalOfficeName}
        showRequestType = {showRequestType}
      />
    );

    // Assertions
    expect(container.querySelector('.hearing-time-scheduled-in-timezone')).toBeTruthy();
    expect(container).toMatchSnapshot();
  });
});
