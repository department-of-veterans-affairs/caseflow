import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { DocketSwitchReviewRequestForm } from 'app/queue/docketSwitch/grant/DocketSwitchReviewRequestForm';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

describe('DocketSwitchReviewRequestForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const defaults = { onSubmit, onCancel, appellantName };


  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<DocketSwitchReviewRequestForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(screen.getByText(sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName))).toBeInTheDocument();
    expect(screen.getByText(DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS)).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchReviewRequestForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();
    expect(screen.getByText('Grant all issues')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });
 
  describe('form validation for all granted issues', () => {

  const receiptDate = '2020-10-01';
  const radioButton = 'Grant all issues'
    const fillForm = async () => {
      //   Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), { target: { value: receiptDate } });


      //   Enter context/instructions
      await fireEvent.change(screen.getByLabelText(/grant all issues/i), { target: { value: radioButton } });
    };


  it('fires onSubmit with correct values', async () => {

    render(<DocketSwitchReviewRequestForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /Continue/i });

      await fillForm();

      await userEvent.click(submit);

      waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith({
          receiptDate,
          disposition,
        });
      });
    });
  });

  describe('form validation for granted partial issues', () => {

  const receiptDate = '2020-10-01';
  const radioButton = 'Grant a partial switch'
    const fillForm = async () => {
      //   Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), { target: { value: receiptDate } });


      //   Enter context/instructions
      await fireEvent.change(screen.getByLabelText(/grant a partial switch/i), { target: { value: radioButton } });
    };


  it('fires onSubmit with correct values', async () => {

    render(<DocketSwitchReviewRequestForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /Continue/i });

      await fillForm();

      await userEvent.click(submit);

      waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith({
          receiptDate,
          disposition,
        });
      });
    });
  });
});
