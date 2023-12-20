import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { DocketSwitchDenialForm } from 'app/queue/docketSwitch/denial/DocketSwitchDenialForm';
import {
  DOCKET_SWITCH_DENIAL_TITLE,
  DOCKET_SWITCH_DENIAL_INSTRUCTIONS,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

const instructions = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';

describe('DocketSwitchDenialForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const defaults = { onSubmit, onCancel, appellantName };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<DocketSwitchDenialForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(
      screen.getByText(sprintf(DOCKET_SWITCH_DENIAL_TITLE, appellantName))
    ).toBeInTheDocument();
    expect(
      screen.getByText(DOCKET_SWITCH_DENIAL_INSTRUCTIONS)
    ).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchDenialForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation & submission', () => {
    const receiptDate = '2020-10-01';
    const fillForm = async () => {
      //   Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: receiptDate },
      });

      //   Enter context/instructions
      await userEvent.type(
        screen.getByRole('textbox', { name: /context/i }),
        instructions
      );
    };

    it('disables submit until all fields valid', async () => {
      render(<DocketSwitchDenialForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /confirm/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      await fillForm();

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });

    it('fires onSubmit with correct values', async () => {
      render(<DocketSwitchDenialForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /confirm/i });

      await fillForm();

      await userEvent.click(submit);

      waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith({
          receiptDate,
          context,
        });
      });
    });
  });
});
