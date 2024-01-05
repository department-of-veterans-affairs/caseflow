import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { leverSaveButton } from 'app/caseDistribution/components/LeverModal';
import { createStore } from '@reduxjs/toolkit';
import COPY from 'COPY';

jest.mock('app/styles/caseDistribution/InteractableLevers.module.scss', () => '');
describe('leverSaveButton Component', () => {
  it('should render the component without errors', () => {
    const mockLeverStore = createStore(() => ({
      levers: [{ title: 'Lever 4', value: 30 }, { title: 'Lever 5', value: 6 }],
      initial_levers: [{ title: 'Lever 4', value: 80 }, { title: 'Lever 5', value: 20 }],
    }));

    render(<leverSaveButton leverStore={mockLeverStore} />);
    expect(screen.getByText('Save')).toBeInTheDocument();
  });

  it('should display the modal when Save button is clicked', () => {
    const mockLeverStore = createStore(() => ({
      levers: [{ title: 'Lever 4', value: 30 }, { title: 'Lever 5', value: 6 }],
      initial_levers: [{ title: 'Lever 4', value: 80 }, { title: 'Lever 5', value: 20 }],
    }));

    render(<leverSaveButton leverStore={mockLeverStore} />);
    const saveButton = screen.getByText('Save');

    fireEvent.click(saveButton);
    expect(screen.getByText(COPY.CASE_DISTRIBUTION_MODAL_TITLE)).toBeInTheDocument();
  });

  it('should not display the modal initially', () => {
    const mockLeverStore = createStore(() => ({
      levers: [{ title: 'Lever 1', value: 10 }, { title: 'Lever 2', value: 20 }],
      initial_levers: [{ title: 'Lever 1', value: 5 }, { title: 'Lever 2', value: 15 }],
    }));

    render(<leverSaveButton leverStore={mockLeverStore} />);
    expect(screen.queryByText(COPY.CASE_DISTRIBUTION_MODAL_TITLE)).toBeNull();
  });
});
