import React from 'react';
import { screen, render } from '@testing-library/react';
import TranscriptionDetailsWebex from '../../../../../app/hearings/components/details/TranscriptionDetailsWebex';
import { axe } from 'jest-axe';

const mockTranscription = {
  taskNumber: '1001',
  transcriber: 'Real Contractor',
  sentToTranscriberDate: '2024-09-14',
  expectedReturnDate: '2024-09-17',
  uploadedToVbmsDate: '2024-09-15',
  returnDate: '2024-09-18'
};

const invalidReturnDateTranscription = {...mockTranscription, returnDate: '2024-08-21'}

const setup = (transcription) => render(<TranscriptionDetailsWebex
  title="Transcription"
  transcription={transcription}
  readOnly="true" />);

describe('TranscriptionDetailsWebex', () => {
  it('renders the text values correctly', async () => {
    setup(mockTranscription);

    expect(await screen.findByText(mockTranscription.taskNumber)).toBeInTheDocument();
    expect(await screen.findByText(mockTranscription.transcriber)).toBeInTheDocument();
    expect(await screen.findByText('09/14/2024')).toBeInTheDocument();
    expect(await screen.findByText('09/17/2024')).toBeInTheDocument();
  });

  it('renders the date picker values correctly', async () => {
    setup(mockTranscription);

    expect((await screen.findByLabelText('Uploaded to VBMS')).
      getAttribute('value')).toBe(mockTranscription.uploadedToVbmsDate);

    expect((await screen.findByLabelText('Return Date')).getAttribute('value')).toBe(mockTranscription.returnDate);
  });

  it('does not render the return date field if invalid', async () => {
    setup(invalidReturnDateTranscription);

    expect((await screen.findByLabelText('Return Date')).getAttribute('value')).toBe('N/A');
  });

  it('matches snapshot', () => {
    const { container } = setup(mockTranscription);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup(mockTranscription);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
