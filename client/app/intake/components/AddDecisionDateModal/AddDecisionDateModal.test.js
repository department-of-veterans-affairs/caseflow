import React from 'react';
import { render, screen } from '@testing-library/react';
import AddDecisionDateModal from './AddDecisionDateModal';
import mockData from './mockData';

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

describe('AddDecisionDateModal', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <AddDecisionDateModal
        {...testProps}
      />
    );

  it('renders', () => {
    setup(mockData);

    expect(screen.getByText('Add Decision Date')).toBeInTheDocument();
  });

  it('disables save button if no date is present', () => {
    setup(mockData);
    const save = screen.getByText('Save');

    expect(save).toHaveAttribute('disabled');

  });
});
