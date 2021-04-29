import React from 'react';
import { screen, render, waitFor, fireEvent, wait } from '@testing-library/react';
import selectEvent from 'react-select-event';
import userEvent from '@testing-library/user-event';
import { AddPoaPage } from 'app/intake/addPOA/AddPoaPage';
import { IntakeProviders } from '../testUtils';
import { ERROR_EMAIL_INVALID_FORMAT } from 'app/../COPY';

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

  it('renders inline email validation error', async () => {
    setup();

    const input = screen.getByLabelText("Representative's name");

    await userEvent.type(input, 'Jane');
    jest.setTimeout(9000000);

    await selectEvent.select(input, 'Claimant not listed');
    screen.debug(input);

    const invalidEmail = 'mail@address';
    const validEmail = 'mail@address.com';
    const emailTextbox = screen.getByRole('textbox', { name: /Representative email Optional/i });

    const inputEmail = async (email) => {
      // input email addresss
      await userEvent.type(emailTextbox, email);

      // trigger onBlur
      expect(emailTextbox).toBe(document.activeElement);
      userEvent.tab(); /* press tab key */
    };

    await inputEmail(invalidEmail);

    await waitFor(() => {
      expect(emailTextbox.value).toBe(invalidEmail);
      expect(screen.getByText(ERROR_EMAIL_INVALID_FORMAT)).toBeDefined();
    });

    // CLEAR INPUT
    fireEvent.change(emailTextbox, { target: { value: '' } });
    expect(emailTextbox.value).toBe('');

    await inputEmail(validEmail);

    await waitFor(() => {
      expect(emailTextbox.value).toBe(validEmail);
      expect(screen.queryByText(ERROR_EMAIL_INVALID_FORMAT)).toBeNull();
    });
  }, 15000);
});
