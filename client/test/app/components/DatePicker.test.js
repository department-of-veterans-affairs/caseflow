import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import {
  selectFromDropdown,
  clickSubmissionButton,
  enterInputValue
} from '../queue/components/modalUtils';

import { axe } from 'jest-axe';

import DatePicker from 'app/components/DatePicker';

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
    const filter = container.querySelector('svg');

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

    expect(handleChange).toHaveBeenCalledWith('');
  });
});
