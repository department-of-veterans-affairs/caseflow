import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import {
  selectFromDropdown,
  clickSubmissionButton,
  enterInputValue
} from '../queue/components/modalUtils';

import { axe } from 'jest-axe';

import DatePicker, { datePickerFilterValue } from 'app/components/DatePicker';

describe('DatePicker', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
    return render(<DatePicker
      label="date-picker"
      onChange={handleChange} {...props}
    />);
  };

  const openFilter = async (container) => {
    const svg = container.querySelectorAll('svg');

    const filter = svg[svg.length - 1];

    fireEvent.click(filter);
    await waitFor(() => {
      expect(screen.getByText('Date filter parameters')).toBeInTheDocument();
    });
  };

  it('renders default state correctly', async () => {
    const { container } = setup();

    openFilter(container);

    expect(container).toMatchSnapshot();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('restores input values correctly', async () => {
    const { container } = setup({ values: ['between,2020-05-14,2024-01-17'] });

    openFilter(container);

    expect(container).toMatchSnapshot();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows one date field for before mode', async () => {
    const { container } = setup({ values: ['before,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('shows one date field for after mode', async () => {
    const { container } = setup({ values: ['after,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('shows one date field for on mode', async () => {
    const { container } = setup({ values: ['on,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('allows dates to be input and form submitted', async () => {
    const { container } = setup();

    openFilter(container);

    selectFromDropdown('Date filter parameters', 'Between these dates');

    enterInputValue('start-date', '2020-05-14');
    enterInputValue('end-date', '2024-01-17');

    clickSubmissionButton('Apply Filter');

    expect(handleChange).toHaveBeenCalledWith('between,2020-05-14,2024-01-17');
  });

  it('allows the filter to be cleared', async () => {
    const { container } = setup({ values: ['on,2020-05-14,'] });

    openFilter(container);

    clickSubmissionButton('Clear filter');

    expect(handleChange).toHaveBeenCalledWith('', true);
  });

  it('has menu position left by default', async () => {
    const { container } = setup();

    openFilter(container);

    expect(container.querySelectorAll('.date-picker.left').length).toBe(1);
  });

  it('allows setting the menu position', async () => {
    const { container } = setup({ settings: { position: 'right' } });

    openFilter(container);

    expect(container.querySelectorAll('.date-picker.left').length).toBe(0);
    expect(container.querySelectorAll('.date-picker.right').length).toBe(1);
  });

  it('has quick buttons off by default', async () => {
    const { container } = setup();

    openFilter(container);

    expect(container.querySelectorAll('.quick-buttons').length).toBe(0);
  });

  it('allows enabling quick buttons', async () => {
    const { container } = setup({ settings: { buttons: true } });

    openFilter(container);

    expect(container.querySelectorAll('.quick-buttons').length).toBe(1);
  });

  it('quick buttons can select last 30 days', async () => {
    jest.spyOn(Date, 'now').mockReturnValue('2024-01-17T03:00:00.000-04:00');

    const { container } = setup({ settings: { buttons: true } });

    openFilter(container);

    clickSubmissionButton('Last 30 days');

    expect(handleChange).toHaveBeenCalledWith('between,2023-12-18,2024-01-17', false);
  });

  it('quick select options can select last 7 days', async () => {
    jest.spyOn(Date, 'now').mockReturnValue('2024-01-17T03:00:00.000-04:00');

    const { container } = setup();

    openFilter(container);

    selectFromDropdown('Date filter parameters', 'Last 7 days');

    expect(screen.queryByText('mm/dd/yyyy')).not.toBeInTheDocument();
    expect(handleChange).toHaveBeenCalledWith('between,2024-01-10,2024-01-17', false);
  });

  it('quick select options can select last 30 days', async () => {
    jest.spyOn(Date, 'now').mockReturnValue('2024-01-17T03:00:00.000-04:00');

    const { container } = setup();

    openFilter(container);

    selectFromDropdown('Date filter parameters', 'Last 30 days');

    expect(screen.queryByText('mm/dd/yyyy')).not.toBeInTheDocument();
    expect(handleChange).toHaveBeenCalledWith('between,2023-12-18,2024-01-17', false);
  });

  it('quick select options can select last 365 days', async () => {
    jest.spyOn(Date, 'now').mockReturnValue('2024-01-17T03:00:00.000-04:00');

    const { container } = setup();

    openFilter(container);

    selectFromDropdown('Date filter parameters', 'Last 365 days');

    expect(screen.queryByText('mm/dd/yyyy')).not.toBeInTheDocument();
    expect(handleChange).toHaveBeenCalledWith('between,2023-01-16,2024-01-17', false);
  });

  describe('datePickerFilterValue', () => {

    it('returns true or false for between dates', async () => {
      expect(datePickerFilterValue('5/15/2024', ['between,2024-05-01,2024-05-31'])).toBeTruthy();
      expect(datePickerFilterValue('6/15/2024', ['between,2024-05-01,2024-05-31'])).toBeFalsy();
    });

    it('returns true or false for before date', async () => {
      expect(datePickerFilterValue('4/15/2024', ['before,2024-05-01,'])).toBeTruthy();
      expect(datePickerFilterValue('5/15/2024', ['before,2024-05-01,'])).toBeFalsy();
    });

    it('returns true or false for after date', async () => {
      expect(datePickerFilterValue('5/15/2024', ['after,2024-05-01,'])).toBeTruthy();
      expect(datePickerFilterValue('4/15/2024', ['after,2024-05-01,'])).toBeFalsy();
    });

    it('returns true or false for on date', async () => {
      expect(datePickerFilterValue('5/1/2024', ['on,2024-05-01,'])).toBeTruthy();
      expect(datePickerFilterValue('5/2/2024', ['on,2024-05-01,'])).toBeFalsy();
    });
  });
});
