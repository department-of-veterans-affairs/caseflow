import React from 'react';
import { render, screen } from '@testing-library/react';
import TranscriptionFilesTable from '../../../../../app/hearings/components/details/TranscriptionFilesTable';

const mockHearing = {
  transcriptionFiles: {
    1: {
      0: {
        id: 1,
        fileStatus: 'Successful upload (AWS)',
        fileName: 'transcription1.pdf',
        dateUploadAws: '2023-08-01',
        hearingType: 'Hearing Type 1',
        docketNumber: '12345'
      },
    },
    2: {
      0: {
        id: 2,
        fileStatus: 'Pending',
        fileName: 'transcription2.pdf',
        dateReturnedBox: '2023-08-05',
        hearingType: 'Hearing Type 2',
        docketNumber: '67890'
      }
    },
    3: {
      0: {
        id: 3,
        fileStatus: 'Successful upload (AWS)',
        fileName: 'transcription.doc',
        dateUploadAws: '2023-09-01',
        hearingType: 'Hearing Type 3',
        docketNumber: '45678'
      }
    }
  }
};

describe('TranscriptionFilesTable', () => {

  it('renders table headers correctly', () => {
    render(<TranscriptionFilesTable hearing={mockHearing} />);
    expect(screen.getByText('Docket(s)')).toBeInTheDocument();
    expect(screen.getByText('Uploaded')).toBeInTheDocument();
    expect(screen.getByText('File Link')).toBeInTheDocument();
    expect(screen.getByText('Status')).toBeInTheDocument();
  });

  it('renders rows based on hearing prop', () => {
    render(<TranscriptionFilesTable hearing={mockHearing} />);

    // Check Docket Name and Number for the first file
    expect(screen.getByText('Hearing Type 1')).toBeInTheDocument();
    expect(screen.getByText('12345')).toBeInTheDocument();

    // Check the file name and status for the second file
    expect(screen.getByText('transcription2.pdf')).toBeInTheDocument();
    expect(screen.getByText('Pending')).toBeInTheDocument();
  });

  it('displays download link for successful AWS uploads', () => {
    render(<TranscriptionFilesTable hearing={mockHearing} />);

    const downloadLink = screen.getByRole('link', { name: 'transcription1.pdf' });
    const downloadLink2 = screen.getByRole('link', { name: 'transcription.doc' });

    expect(downloadLink).toHaveAttribute('href', '/hearings/transcription_file/1/download');
    expect(downloadLink2).toHaveAttribute('href', '/hearings/transcription_file/3/download');
  });

  it('displays file name without link for pending AWS uploads', () => {
    render(<TranscriptionFilesTable hearing={mockHearing} />);

    const downloadLink = screen.queryByRole('link', { name: 'transcription2.pdf' });

    expect(downloadLink).not.toBeInTheDocument();
    expect(screen.getByText('transcription2.pdf')).toBeInTheDocument();
  });

  it('renders alternating row classes based on isEvenGroup', () => {
    render(<TranscriptionFilesTable hearing={mockHearing} />);

    const firstRow = screen.getByText('12345').closest('tr');
    const secondRow = screen.getByText('67890').closest('tr');

    expect(firstRow).toHaveClass('even-row-group');
    expect(secondRow).toHaveClass('odd-row-group');
  });

  it('handles empty transcriptionFiles gracefully', () => {
    const emptyHearing = { transcriptionFiles: {} };

    render(<TranscriptionFilesTable hearing={emptyHearing} />);

    // Table should render without rows
    expect(screen.queryByText('transcription1.pdf')).not.toBeInTheDocument();
  });
});
