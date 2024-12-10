import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import { ErrorsFoundAndCorrectedModal } from '../../../../app/queue/components/ErrorsFoundAndCorrectedModal';
import ApiUtil from '../../../../app/util/ApiUtil';

describe('ErrorsFoundAndCorrectedModal', () => {
  const closeModal = jest.fn();
  const requestPatch = jest.fn();
  const getSpy = jest.spyOn(ApiUtil, 'get');

  const defaultProps = {
    taskId: '1000',
    closeModal,
    requestPatch,
    type: 'ReviewTranscriptTask',
    appealId: '12',
    task: {
      taskId: '1000',
      type: 'ReviewTranscriptTask'
    }

  };

  beforeEach(() => {
    getSpy.mockImplementation(() => new Promise((resolve) => resolve({ body: { file_name: 'test.pdf' } })));
  });

  it('renders correctly', () => {

    const { container } = render(<ErrorsFoundAndCorrectedModal {...defaultProps} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<ErrorsFoundAndCorrectedModal {...defaultProps} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('displays the default page elements with default props', () => {
    render(
      <ErrorsFoundAndCorrectedModal {...defaultProps} />
    );

    const textarea = screen.getByRole('textbox');

    expect(screen.getByText('Upload transcript to VBMS')).toBeInTheDocument();
    expect(screen.getByText('Please upload the revised transcript file for upload to VBMS.')).
      toBeInTheDocument();
    expect(screen.getByText('Please select PDF')).toBeInTheDocument();
    expect(screen.getByText('Choose from folder')).toBeInTheDocument();
    expect(screen.getByText('Please provide context and instructions for this action')).
      toBeInTheDocument();
    expect(textarea.value).toBe('');
  });

  it('can handle a file upload', async () => {
    const file = new File(['test'], 'test.pdf', { type: 'application/pdf' });

    render(
      <ErrorsFoundAndCorrectedModal {...defaultProps} />
    );

    const input = screen.getByLabelText(/Choose from folder/i);

    userEvent.upload(input, file);

    await waitFor(() => {
      expect(input.files.length).toBe(1);
      // Two nstanceso file names. Existing file name and file name uploaded by user
      expect(screen.getAllByText('test.pdf')).toHaveLength(2);
      expect(screen.getByText('Selected file')).toBeInTheDocument();
      expect(screen.getByText('Change file')).toBeInTheDocument();
    });
  });

  it('display error when file name does not match the uploaded file name', async () => {
    const file = new File(['test1'], 'test1.pdf', { type: 'application/pdf' });

    render(
      <ErrorsFoundAndCorrectedModal {...defaultProps} />
    );

    expect(screen.getByText('Upload to VBMS').closest('button')).
      toBeDisabled();
    expect(
      screen.queryByText(/File name must exactly macth the transcript file name/i)
    ).not.toBeInTheDocument();

    const input = screen.getByLabelText(/Choose from folder/i);
    const textarea = screen.getByRole('textbox');

    userEvent.upload(input, file);

    userEvent.type(textarea, 'This is a note.');

    await waitFor(() => {
      expect(
        screen.getByText(/File name must exactly match the transcript file name/i)
      ).toBeInTheDocument();
      expect(screen.getByText('Upload to VBMS').closest('button')).
        toBeDisabled();
    });
  });

  it('the submit button is enabled when file name matched and fields filled out', async () => {
    const file = new File(['test'], 'test.pdf', { type: 'application/pdf' });

    render(
      <ErrorsFoundAndCorrectedModal {...defaultProps} />
    );

    expect(screen.getByText('Upload to VBMS').closest('button')).
      toBeDisabled();

    const input = screen.getByLabelText(/Choose from folder/i);
    const textarea = screen.getByRole('textbox');

    userEvent.upload(input, file);

    await waitFor(() => {
      expect(screen.getByText('Upload to VBMS').closest('button')).
        toBeDisabled();
    });

    userEvent.type(textarea, 'This is a note.');

    await waitFor(() => {
      expect(screen.getByText('Upload to VBMS').closest('button')).
        toBeEnabled();
    });
  });
});
