import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import BuildScheduleUpload from '../../../../../../client/app/hearings/components/BuildScheduleUpload';
import { SPREADSHEET_TYPES } from '../../../../../../client/app/hearings/constants';

describe('BuildScheduleUpload', () => {
  it('does not show the date selector when file type is null', () => {
    render(<MemoryRouter><BuildScheduleUpload /></MemoryRouter>);

    expect(screen.getByText('Upload Files')).toBeInTheDocument();
    expect(screen.getByText('Please select the file you are uploading and choose a date range.')).toBeInTheDocument();
    expect(screen.queryByText('Please input a date range')).not.toBeInTheDocument();
  });

  it('shows the date selector when file type is \'Judge\'', () => {
    render(
      <MemoryRouter>
        <BuildScheduleUpload
          fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
        />
      </MemoryRouter>
    );
    expect(screen.getByText('What are you uploading?')).toBeInTheDocument();
  });

  it('displays errors when set', () => {
    render(
      <MemoryRouter>
        <BuildScheduleUpload
          fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
          uploadJudgeFormErrors={['Validation failed: The template was not followed.']}
        />
      </MemoryRouter>
    );

    expect(screen.getByText('Validation failed: The template was not followed.')).toBeInTheDocument();
  });
});
