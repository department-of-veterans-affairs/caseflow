import React from 'react';
import { render, screen } from '@testing-library/react';
import AddDecisionDateModal from './AddDecisionDateModal';
import mockData from './mockData';

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

// Ensures the snapshot always matches the same date.
const fakeDate = new Date(2023, 7, 10, 0, 0, 0, 0);

describe('AddDecisionDateModal', () => {

  beforeAll(() => {
    // Ensure consistent handling of dates across tests
    jest.useFakeTimers('modern');
    jest.setSystemTime(fakeDate);
  });

  afterAll(() => {
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  const setup = (testProps) =>
    render(
      <AddDecisionDateModal
        {...testProps}
      />
    );

  it('renders', () => {
    const modal = setup(mockData);

    expect(modal).toMatchSnapshot();
    expect(screen.getByText('Add Decision Date')).toBeInTheDocument();
  });

  it('displays Edit Decision Date if the issue has an editedDecisionDate', () => {
    setup({ ...mockData, currentIssue: { ...mockData.currentIssue, editedDecisionDate: '12/7/2017' } });

    expect(screen.getByText('Edit Decision Date')).toBeInTheDocument();
  });

  it('disables save button if no date is present', () => {
    setup(mockData);
    const save = screen.getByText('Save');

    expect(save).toHaveAttribute('disabled');
  });
});
