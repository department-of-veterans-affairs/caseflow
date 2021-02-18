import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { DocketSwitchReviewRequestForm } from 'app/queue/docketSwitch/grant/DocketSwitchReviewRequestForm';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

describe('DocketSwitchReviewRequestForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const issues = [
    { id: 1, program: 'compensation', description: 'PTSD denied' },
    { id: 2, program: 'compensation', description: 'Left  knee denied' },
  ];
  const docketFrom = 'evidence_submission';
  const defaults = { onSubmit, onCancel, appellantName, docketFrom, issues };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(
      <DocketSwitchReviewRequestForm {...defaults} />
    );

    expect(container).toMatchSnapshot();

    expect(
      screen.getByText(
        sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName)
      )
    ).toBeInTheDocument();
    expect(
      screen.getByText(DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS)
    ).toBeInTheDocument();
  });

  it('disables current docket', async () => {
    render(<DocketSwitchReviewRequestForm {...defaults} />);

    // Set disposition to show docket selection
    await userEvent.click(
      screen.getByRole('radio', { name: /grant all issues/i })
    );

    await waitFor(() => {
      expect(
        screen.getByText('Evidence Submission (current docket)')
      ).toBeInTheDocument();
      expect(
        screen.getByRole('radio', { name: /evidence submission/i })
      ).toBeDisabled();
    });
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

    it('fires onSubmit with correct values', async () => {
      render(<DocketSwitchReviewRequestForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /Continue/i });

      // Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: receiptDate },
      });

      //   Set disposition
      await userEvent.click(
        screen.getByRole('radio', { name: /grant all issues/i })
      );

      // Wait for docketType to show up
      await waitFor(() => {
        expect(
          screen.getByRole('radio', { name: /direct review/i })
        ).toBeInTheDocument();
      });

      //   Set docketType
      await userEvent.click(
        screen.getByRole('radio', { name: /direct review/i })
      );

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
  });

  describe('form validation for granted partial issues', () => {
    const receiptDate = '2020-10-01';
    const disposition = 'partially_granted';
    const docketType = 'direct_review';
    const issueIds = ['1'];
    const fillForm = async () => {
      //   Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: receiptDate },
      });

      //   Enter context/instructions
      await fireEvent.change(screen.getByLabelText(/grant a partial switch/i), {
        target: { value: disposition },
      });
    };

    it('fires onSubmit with correct values', async () => {
      render(<DocketSwitchReviewRequestForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /Continue/i });

      // Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: receiptDate },
      });

      //   Set disposition
      await userEvent.click(
        screen.getByRole('radio', { name: /grant a partial switch/i })
      );

      // Wait for docketType to show up
      await waitFor(() => {
        expect(
          screen.getByRole('radio', { name: /direct review/i })
        ).toBeInTheDocument();
      });

      //   Set docketType
      await userEvent.click(
        screen.getByRole('radio', { name: /direct review/i })
      );

      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      //   Select an issue
      await userEvent.click(
        screen.getByRole('checkbox', { name: /ptsd denied/i })
      );

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
  });
});
