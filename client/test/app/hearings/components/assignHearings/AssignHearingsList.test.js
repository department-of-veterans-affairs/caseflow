import React from 'react';
import { render } from '@testing-library/react';

import { AssignHearingsList } from 'app/hearings/components/assignHearings/AssignHearingsList';
import { amaHearing, legacyHearing, defaultHearing, defaultHearingDay } from 'test/data';

// St. Petersburg FL
const regionalOffice = 'RO17';
const hearings = [defaultHearing, amaHearing, legacyHearing];

describe('AssignHearingsList', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const hearingsList = render(
      <AssignHearingsList
        regionalOffice={regionalOffice}
        hearings={hearings}
        hearingDay={defaultHearingDay}
      />
    );

    expect(document.getElementsByClassName('time-slot-card')).toHaveLength(3);
    expect(hearingsList).toMatchSnapshot();
  });

  test('Displays no hearings message when there are no hearings', () => {
    // Run the test
    const hearingsList = render(
      <AssignHearingsList
        regionalOffice={regionalOffice}
        hearings={[]}
        hearingDay={defaultHearingDay}
      />
    );

    expect(document.getElementsByClassName('time-slot-card')).toHaveLength(0);
    expect(document.getElementsByClassName('no-hearings-label')[0]).
      toHaveTextContent('No Upcoming hearings to display');
    expect(hearingsList).toMatchSnapshot();
  });
});
