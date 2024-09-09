import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import BuildSchedule from '../../../../../../client/app/hearings/components/BuildSchedule';

describe('BuildSchedule', () => {
  it('renders table with upload history', () => {
    render(<MemoryRouter><BuildSchedule
      pastUploads={[
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'JudgeSchedulePeriod',
          createdAt: '07/03/2018',
          userFullName: 'Justin Madigan',
          fileName: 'fake file name',
          finalized: true
        }
      ]}
    /></MemoryRouter>);

    expect(screen.getByText('Judge')).toBeInTheDocument();
    expect(screen.getByText('07/03/2018')).toBeInTheDocument();
    expect(screen.getByText('Justin Madigan')).toBeInTheDocument();
    expect(screen.getByText('Download')).toBeInTheDocument();
  });

  it('renders a success alert when a schedule period has been created', () => {
    render(<MemoryRouter><BuildSchedule
      pastUploads={[
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'JudgeSchedulePeriod',
          createdAt: '07/03/2018',
          userFullName: 'Justin Madigan',
          fileName: 'fake file name'
        }
      ]}
      displaySuccessMessage
      schedulePeriod={{
        type: 'JudgeSchedulePeriod',
        startDate: '2018-07-04',
        endDate: '2018-07-26'
      }}
    /></MemoryRouter>);

    expect(screen.getByText('You have successfully assigned judges to hearings between 07/04/2018 and 07/26/2018')).toBeInTheDocument();
  });
});
