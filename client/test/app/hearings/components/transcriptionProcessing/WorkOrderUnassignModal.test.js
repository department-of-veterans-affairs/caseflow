import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import WorkOrderUnassignModal
  from '../../../../../app/hearings/components/transcriptionProcessing/WorkOrderUnassignModal';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil');

describe('WorkOrderUnassignModal', () => {
  const onClose = jest.fn();
  const workOrderNumber = 'BVA202401';

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders the modal with correct content', () => {
    render(<WorkOrderUnassignModal onClose={onClose} workOrderNumber={workOrderNumber} />);

    expect(screen.getByText(`#${workOrderNumber}`)).
      toBeInTheDocument();
    expect(screen.getByText(
      'Unassigning this order will return all appeals back to the Unassigned Transcription queue.'
    )).toBeInTheDocument();
    expect(screen.getByText(
      "Please ensure that all hearing files are removed from the contractors's box.com folder."
    )).toBeInTheDocument();
  });

  test('closes the modal on successful unassign', async () => {
    ApiUtil.post.mockResolvedValue({ status: 204 });

    render(<WorkOrderUnassignModal onClose={onClose} workOrderNumber={workOrderNumber} />);

    fireEvent.click(screen.getByText('Unassign order'));

    await waitFor(() => {
      expect(onClose).toHaveBeenCalled();
    });
  });

});
