import React from 'react';
import { render, waitFor, screen, fireEvent } from '@testing-library/react';
import COPY from '../../../../../COPY';
import { RemoveContractorModal }
  from '../../../../../app/hearings/components/transcriptionProcessing/RemoveContractorModal';

const onCancel = jest.fn();
const onConfirm = jest.fn();

const testContractor = {
  id: 1,
  name: 'Test Contractor',
};

const renderRemoveContractorModal = (contractors = []) => {
  return render(
    <RemoveContractorModal
      onCancel={onCancel}
      onConfirm={onConfirm}
      title="Remove contractor"
      contractors={contractors}
    />
  );
};

describe('RemoveContractorModal', () => {
  test('contains expected labels, fields and buttons', () => {
    const component = renderRemoveContractorModal([testContractor]);

    expect(component).toMatchSnapshot();
  });

  test('calls onCancel when cancel button is clicked', async () => {
    renderRemoveContractorModal([testContractor]);
    fireEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  test('calls onConfirm when confirm button is clicked', () => {
    renderRemoveContractorModal([testContractor]);

    fireEvent.change(screen.getByLabelText('Contractor'), { target: { value: testContractor.id } });

    fireEvent.click(screen.getByRole('button', { name: COPY.MODAL_CONFIRM_BUTTON }));
    waitFor(() => expect(onConfirm).toHaveBeenCalled());
  });

  test('disables confirm button when no contractor is selected', () => {
    renderRemoveContractorModal([testContractor]);
    expect(screen.getByText(COPY.MODAL_CONFIRM_BUTTON).closest('button')).toBeDisabled();
  });

});
