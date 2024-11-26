import React from 'react';
import { render } from '@testing-library/react';
import selectEvent from 'react-select-event';
import TranscriptionDetailsInputs from 'app/hearings/components/details/TranscriptionDetailsInputs';

describe('TranscriptionDetailsInputs', () => {
  const mockUpdate = jest.fn();
  const transcription = {
    transcriber: '1',
  };
  const transcriptionContractors = {
    1: 'Genesis Government Solutions, Inc.',
    2: 'Jamison Professional Services',
    3: 'The Ravens Group, Inc.'
  };

  it('renders correctly', async () => {
    const { findByLabelText, getByText } = render(
      <TranscriptionDetailsInputs
        transcription={transcription}
        update={mockUpdate}
        readOnly={false}
        transcriptionContractors={transcriptionContractors}
      />
    );

    const dropdown = await findByLabelText('Transcriber');

    expect(dropdown).toBeInTheDocument();
    expect(getByText(transcriptionContractors[1])).toBeInTheDocument();
  });

  it('updates correctly', async () => {
    const { getByLabelText } = render(
      <TranscriptionDetailsInputs
        transcription={transcription}
        update={mockUpdate}
        readOnly={false}
        transcriptionContractors={transcriptionContractors}
      />
    );

    await selectEvent.select(getByLabelText('Transcriber'), transcriptionContractors['2']);
    expect(mockUpdate).toHaveBeenCalledWith({ transcriber: '2' });
  });
});
