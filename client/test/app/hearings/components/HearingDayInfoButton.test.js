import React from 'react';

import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import HearingDayInfoButton from 'app/hearings/components/assignHearings/HearingDayInfoButton';

describe('HearingDayInfoButton', () => {
  const setSelectedValue = jest.fn();

  const props = {
    hearingDay:
      {
        judgeFirstName: 'Jonas',
        judgeLastName: 'Jerengal',
        room: '14',
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

  /*
  it('correctly sets checkbox status when all are unchecked', () => {
    const uncheckedOptions = props.options.map((opt) => {
      return { ...opt, checked: false };
    });
    const allFalseOptionsProps = { ...props, options: uncheckedOptions };

    const component = render(<FilterOption {...allFalseOptionsProps} />);
    const options = component.getAllByRole('checkbox');
    const checked = options.filter((el) => el.checked);

    expect(checked.length).toBe(0);
  });

  it('correctly sets checkbox status when all are checked', () => {
    const checkedOptions = props.options.map((opt) => {
      return { ...opt, checked: true };
    });
    const allTrueOptionsProps = { ...props, options: checkedOptions };

    const component = render(<FilterOption {...allTrueOptionsProps} />);
    const options = component.getAllByRole('checkbox');
    const checked = options.filter((el) => el.checked);

    expect(checked.length).toBe(options.length);
  });

  it('correctly calls setSelectedValue', async () => {
    const component = render(<FilterOption {...props} />);

    const options = component.getAllByRole('checkbox');
    const opt = props.options[1];
    const checkedBefore = options.filter((el) => el.checked);

    expect(checkedBefore.length).toBe(1);

    await userEvent.click(screen.getByLabelText(opt.displayText));

    // Calls onChange handler
    expect(setSelectedValue).toHaveBeenCalledTimes(1);

    // While we aren't updating value, handleChange is still getting called
    expect(setSelectedValue).toHaveBeenLastCalledWith(opt.value);

    const checkedAfter = options.filter((el) => el.checked);

    // Value should not have been updated, since we're not doing that
    expect(checkedAfter.length).toBe(1);
  });
  */
});
