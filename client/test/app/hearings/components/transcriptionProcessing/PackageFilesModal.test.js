import React from 'react';
import { render, waitFor, screen, fireEvent } from '@testing-library/react';
import COPY from '../../../../../COPY';
import ApiUtil from '../../../../../app/util/ApiUtil';
import PackageFilesModal from '../../../../../app/hearings/components/transcriptionProcessing/PackageFilesModal';
import { transcriptionContractors } from '../../../../data/transcriptionContractors';

const onCancel = jest.fn();

const renderModal = () => {
  render(<PackageFilesModal onCancel={onCancel} contractors={transcriptionContractors} />);
};

describe('Package files modal', () => {
  it('title displays correctly', () => {
    renderModal();
    expect(screen.getByText('Package files')).toBeInTheDocument();
  });

  it('radio button displays correct dates', () => {
    const mockedDate = new Date(2024, 6, 31);

    jest.useFakeTimers('modern');
    jest.setSystemTime(mockedDate);
    renderModal();
    jest.useRealTimers();
    expect(screen.getByRole('radio', { name: 'Return in 15 days (8/21/2024)' })).toBeInTheDocument();
    expect(screen.getByRole('radio', { name: 'Expedite (Maximum of 5 days)', value: { text: '8/7/2024' } })).
      toBeInTheDocument();

  });

  it('dropdown displays contractors', () => {
    renderModal();
    const dropdown = screen.getByRole('combobox');

    fireEvent.change(dropdown, { target: { value: 3 } });
    expect(screen.getByText('The Ravens Group, Inc.')).toBeInTheDocument();
  });
});
