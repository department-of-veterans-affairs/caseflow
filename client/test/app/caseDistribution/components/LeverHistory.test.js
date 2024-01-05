import React from 'react';
import { render, screen } from '@testing-library/react';
import LeverHistory from 'app/caseDistribution/components/LeverHistory';

jest.mock('app/styles/caseDistribution/LeverHistory.module.scss', () => '');
describe('LeverHistory', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <LeverHistory {...testProps} />
    );

  it('renders the "LeverHistory Component" with the proper history data imported', () => {

    let testProps = {
      historyData: [{
        created_at: '2023-07-01 10:10:01',
        user: 'john_smith',
        titles: ['Batch Size Per Attorney', 'Request More Cases Minimum'],
        original_values: ['10', 'false'],
        current_values: ['23', 'true'],
        units: ['cases', '']
      }]
    };

    setup(testProps);

    expect(screen.getByText('2023-07-01 10:10:01')).toBeInTheDocument();
    expect(screen.getByText('john_smith')).toBeInTheDocument();
    expect(screen.getByText('Batch Size Per Attorney')).toBeInTheDocument();
    expect(screen.getByText('Request More Cases Minimum')).toBeInTheDocument();
    expect(screen.getByText('10 cases')).toBeInTheDocument();
    expect(screen.getByText('23 cases')).toBeInTheDocument();
  });

});
