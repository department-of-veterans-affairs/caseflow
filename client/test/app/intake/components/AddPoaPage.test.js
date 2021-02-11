import React from 'react';
import { screen, render, fireEvent, within, act, waitFor} from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { AddPoaPage } from 'app/intake/addPoa/AddPoaPage';
import { IntakeProviders } from '../testUtils';

describe('AddPoaPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack};
  const setup = () => {
    return render(<AddPoaPage  {...defaults}/>, { wrapper: IntakeProviders });
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(
      screen.getByText("Add Claimant's POA")
    ).toBeInTheDocument();
  });

  it('fires onBack', async () => {
    const { container } = setup();

    const backButton = screen.getByRole('button', { name: /back/i });
    expect(onBack).not.toHaveBeenCalled();
     
    await userEvent.click(backButton);
    expect(onBack).not.toHaveBeenCalled();
  });
});
