import React from 'react';

import { TimeSlotCard } from 'app/hearings/components/assignHearings/TimeSlotCard';
import { render } from '@testing-library/react';
import { getHearingDetails, getHearingType, defaultHearing, defaultHearingDay } from 'test/data';

// St. Petersburg FL
const regionalOffice = 'RO17';

describe('TimeSlotCard', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const card = render(
      <TimeSlotCard regionalOffice={regionalOffice} hearing={defaultHearing} hearingDay={defaultHearingDay} />
    );

    // Row 1 data
    const veteranName = `${defaultHearing.appellantFirstName} ${defaultHearing.appellantLastName}`;
    const headerLabel = `${veteranName} · Veteran ID: ${defaultHearing.veteranFileNumber}`;

    // Row 2 data
    const secondRowLabel = getHearingDetails(defaultHearing, true);

    // Row 3 data
    const lastRowLabel = getHearingType(defaultHearing);

    expect(document.getElementsByClassName('usa-width-one-fourth')).toHaveLength(1);
    expect(document.getElementsByClassName('usa-width-three-fourths')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-card-time')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-card-label')).toHaveLength(2);
    expect(card.getAllByText('·')).toHaveLength(5);

    // Row 1
    expect(document.getElementsByClassName('time-slot-card-label')[1]).toHaveTextContent(headerLabel);

    // Row 2
    expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(secondRowLabel);

    // Row 3
    expect(document.getElementsByClassName('time-slot-details')[1]).toHaveTextContent(lastRowLabel);

    expect(card).toMatchSnapshot();
  });
});
