import React from 'react';
import { screen, render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AddPoaPage } from 'app/intake/addPOA/AddPoaPage';
import { IntakeProviders } from '../testUtils';

describe('AddPoaPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack };
  const setup = () => {
    return render(<AddPoaPage {...defaults} />, { wrapper: IntakeProviders });
  };

  it('renders default state correctly', async () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    await waitFor(() => {
      expect(
        screen.getByText("Add Claimant's POA")
      ).toBeInTheDocument();
    });
  });

  it('fires onBack', async () => {
    setup();

    const backButton = screen.getByRole('button', { name: /back/i });

    expect(onBack).not.toHaveBeenCalled();

    await waitFor(() => {
      userEvent.click(backButton);
      expect(onBack).not.toHaveBeenCalled();
    });
  });
});
