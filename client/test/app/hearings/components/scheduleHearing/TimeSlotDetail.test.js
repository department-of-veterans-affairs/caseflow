import React from 'react';

import { TimeSlotDetail } from 'app/hearings/components/scheduleHearing/TimeSlotDetail';
import { render } from '@testing-library/react';
import { getHearingDetailsArray, getHearingType, defaultHearing, defaultHearingDay } from 'test/data';

const testLabel = 'Something';

// St. Petersburg FL
const defaultProps = {
  ...defaultHearing,
  issueCount: defaultHearing.currentIssueCount,
  label: testLabel,
  hearingDay: defaultHearingDay,
  regionalOffice: 'RO17'
};

// Row 2 data
const secondRowLabelArray = getHearingDetailsArray(defaultProps, '');

// Row 3 data
const lastRowLabel = getHearingType(defaultProps);

describe('TimeSlotDetail', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const card = render(
      <TimeSlotDetail {...defaultProps} />
    );

    expect(document.getElementsByClassName('time-slot-details')).toHaveLength(0);
    expect(card.baseElement).toHaveTextContent(testLabel);
    expect(card).toMatchSnapshot();
  });

  test('Displays details when showDetails is true', () => {
    // Run the test
    const card = render(
      <TimeSlotDetail {...defaultProps} showDetails />
    );

    expect(document.getElementsByClassName('time-slot-details')).toHaveLength(1);
    secondRowLabelArray.forEach((elem) => {
      expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(elem);
    });
    expect(card.baseElement).toHaveTextContent(testLabel);
    expect(card).toMatchSnapshot();
  });

  test('Displays hearing info when showType is true', () => {
    // Run the test
    const card = render(
      <TimeSlotDetail {...defaultProps} showType />
    );

    expect(document.getElementsByClassName('time-slot-details')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(lastRowLabel);
    expect(card.baseElement).toHaveTextContent(testLabel);
    expect(card).toMatchSnapshot();
  });

  test('Displays hearing info and details when showType and showDetails are true', () => {
    // Run the test
    const card = render(
      <TimeSlotDetail {...defaultProps} showType showDetails />
    );

    expect(document.getElementsByClassName('time-slot-details')).toHaveLength(2);

    getHearingDetailsArray(defaultProps, true).forEach((elem) => {
      expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(elem);
    });
    expect(document.getElementsByClassName('time-slot-details')[1]).toHaveTextContent(lastRowLabel);
    expect(card.baseElement).toHaveTextContent(testLabel);
    expect(card).toMatchSnapshot();
  });
});
