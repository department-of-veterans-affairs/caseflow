// libraries
import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import moment from 'moment-timezone/moment-timezone';
// caseflow
import { TimeModal } from 'app/hearings/components/modalForms/TimeModal';

const defaultProps = {
  title: 'Choose a custom time',
  hearingDayDate: '2021-05-09',
  ro: {
    city: 'Los Angeles',
    timezone: 'America/Los_Angeles'
  },
  onConfirm: jest.fn(),
  onCancel: jest.fn(),
};

const setup = (props = {}) => {
  const mergedProps = { ...defaultProps, ...props };

  const utils = render(<TimeModal {...mergedProps} />);
  const container = utils.container;

  return { container, utils };
};

it('renders correctly', () => {
  const { container } = setup();

  expect(container).toMatchSnapshot();
});

it('passes a11y testing', async () => {
  const { container } = setup();
  const results = await axe(container);

  expect(results).toHaveNoViolations();
});

it('sends the correct time onConfirm', async () => {
  // confirmFunction receives a moment object, convert it to a string
  // for comparison or jest matchers fail
  const onConfirm = jest.fn((i) => i.toISOString());
  const hearingDayDate = '2021-05-10';
  const { utils } = setup({ onConfirm, hearingDayDate });

  const timeString = '8:30 AM';
  const isoString = moment.tz(
    `${hearingDayDate} ${timeString}`,
    'YYYY-MM-DD h:mm A',
    'America/Los_Angeles'
  ).toISOString();

  userEvent.type(utils.getByRole('textbox'), `${timeString}{enter}`);

  expect(onConfirm).toHaveBeenCalledTimes(0);

  await fireEvent.click(utils.getByText('Choose time'));

  expect(onConfirm).toHaveBeenCalledTimes(1);

  expect(onConfirm).toHaveReturnedWith(isoString);
});

it('calls onCancel when cancelled', async () => {
  const onCancel = jest.fn();
  const { utils } = setup({ onCancel });

  expect(onCancel).toHaveBeenCalledTimes(0);

  await fireEvent.click(utils.getByText('Cancel'));

  expect(onCancel).toHaveBeenCalledTimes(1);

});

it('shows error message when blank is confirmed', async () => {
  const { utils } = setup();

  expect(utils.queryByText('Please enter a hearing start time.')).toBeFalsy();

  await fireEvent.click(utils.getByText('Choose time'));

  expect(utils.getByText('Please enter a hearing start time.')).toBeDefined();
});

it('shows info alert when ro is not in eastern timezone', () => {
  const ro = {
    city: 'Los Angeles',
    timezone: 'America/Los_Angeles'
  };
  const { utils } = setup({ ro });

  userEvent.type(utils.getByRole('textbox'), '10:30 am{enter}');

  expect(utils.getByText('The hearing will start at 1:30 PM Eastern Time')).toBeDefined();

});

it('does not show an info alert when ro is in eastern timezone', () => {
  const ro = {
    city: 'New York',
    timezone: 'America/New_York'
  };
  const { utils } = setup({ ro });

  userEvent.type(utils.getByRole('textbox'), '10:30 am{enter}');

  expect(utils.queryByText('The hearing will start at')).toBeFalsy();
});
