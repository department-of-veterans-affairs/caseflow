import React from 'react';

import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import HearingDayInfoButton from 'app/hearings/components/assignHearings/HearingDayInfoButton';

describe('HearingDayInfoButton', () => {
  const setSelectedValue = jest.fn();

  const props = {
    hearingDay:
      {
        scheduledFor: '04/12/2021',
        judgeFirstName: 'Jonas',
        judgeLastName: 'Jerengal',
        room: '14',
        requestType: 'V',
        readableRequestType: 'video',
        hearings: {
          hearing_1: {},
          hearing_2: {},
        },
        totalSlots: 8,
      },
    selected: false,
    onSelectedHearingDayChange: setSelectedValue,
  };

  it('renders correctly', () => {
    const { container } = render(<HearingDayInfoButton {...props} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<HearingDayInfoButton {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has correct class when selected', () => {
    const selectedProps = { ...props, selected: true };
    const utils = render(<HearingDayInfoButton {...selectedProps} />);
    const button = utils.getByRole('button');

    expect(button).toHaveClass('selected-hearing-day-info-button');
  });

  it('has correct class when unselected', () => {
    const selectedProps = { ...props, selected: false };
    const utils = render(<HearingDayInfoButton {...selectedProps} />);
    const button = utils.getByRole('button');

    expect(button).toHaveClass('unselected-hearing-day-info-button');
  });

  it('calls setSelected on click', async () => {
    const utils = render(<HearingDayInfoButton {...props} />);
    const button = utils.getByRole('button');

    expect(setSelectedValue).toHaveBeenCalledTimes(0);
    await userEvent.click(button);
    expect(setSelectedValue).toHaveBeenCalledTimes(1);
  });

  it('renders the Docket readable request type when Docket is type Virtual', () => {
    props.requestType = 'R';

    const { container } = render(<HearingDayInfoButton {...props} />);

    expect(container).toMatchSnapshot();
  });
});
