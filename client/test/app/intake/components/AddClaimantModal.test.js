import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import faker from 'faker';

import { AddClaimantModal } from 'app/intake/components/AddClaimantModal';

const DEBOUNCE = 250;

// Set up sample data & async fn for performing fuzzy search
// Actual implementation performs fuzzy search via backend ruby gem
const totalRecords = 500;
const data = Array.from({ length: totalRecords }, () => ({
  name: faker.name.findName(),
  participant_id: faker.random.number({ min: 600000000, max: 600000000 + totalRecords })
}));
const performQuery = async (search = '') => {
  const regex = RegExp(search, 'i');

  return data.filter((item) => regex.test(item.name));
};

describe('AddClaimantModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  jest.useFakeTimers('modern');

  it('renders correctly', () => {
    const { container } = render(<AddClaimantModal onSearch={performQuery} onCancel={onCancel} onSubmit={onSubmit} />);

    expect(container).toMatchSnapshot();
  });

  it('should fire cancel event', () => {
    render(<AddClaimantModal onSearch={performQuery} onCancel={onCancel} onSubmit={onSubmit} />);

    fireEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  test('it prevents submit unless valid', async () => {
    render(<AddClaimantModal onSearch={performQuery} onCancel={onCancel} onSubmit={onSubmit} />);

    const input = screen.getByLabelText(/claimant's name/i);
    const submit = screen.getByRole('button', { name: /add this claimant/i });

    userEvent.click(submit);
    expect(onSubmit).not.toHaveBeenCalled();

    // Enter sufficient search, and wait for select options to show
    await userEvent.type(input, data[0].name.substr(0, 4));
    jest.advanceTimersByTime(DEBOUNCE);
    await waitFor(() => screen.getByText(data[0].name));

    // Select claimant
    await userEvent.click(screen.getByText(data[0].name));

    // Click submit
    userEvent.click(submit);
    expect(onSubmit).toHaveBeenCalled();
  });

  describe('claimant search', () => {
    jest.useFakeTimers('modern');

    let func;

    beforeEach(() => {
      func = jest.fn(performQuery);
    });

    test('enforces minimum characters', async () => {
      render(<AddClaimantModal onSearch={func} onCancel={onCancel} onSubmit={onSubmit} />);
      const input = screen.getByLabelText(/claimant's name/i);

      // enter insufficient characters
      await userEvent.type(input, data[0].name.substr(0, 2));
      jest.advanceTimersByTime(DEBOUNCE);
      expect(func).not.toHaveBeenCalled();

      await userEvent.type(input, data[0].name.substr(0, 1));
      jest.advanceTimersByTime(DEBOUNCE);
      expect(func).toHaveBeenCalled();
    });

    test('just once', async () => {
      render(<AddClaimantModal onSearch={func} onCancel={onCancel} onSubmit={onSubmit} />);
      const input = screen.getByLabelText(/claimant's name/i);

      // enter insufficient characters
      await userEvent.type(input, 'A');
      jest.advanceTimersByTime(DEBOUNCE);
      expect(func).not.toHaveBeenCalled();

      await userEvent.type(input, 'BC');
      jest.advanceTimersByTime(DEBOUNCE);
      expect(func).toHaveBeenCalled();
      expect(func).toBeCalledTimes(1);
      await userEvent.type(input, 'DEF');
      expect(func).toBeCalledTimes(1);
      await userEvent.type(input, 'GHI');
      expect(func).toBeCalledTimes(1);
      jest.advanceTimersByTime(DEBOUNCE);
      expect(func).toBeCalledTimes(2);
    });
  });
});
