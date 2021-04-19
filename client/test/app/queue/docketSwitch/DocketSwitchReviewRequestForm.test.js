import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { DocketSwitchReviewRequestForm } from 'app/queue/docketSwitch/grant/DocketSwitchReviewRequestForm';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS,
  DOCKET_SWITCH_REVIEW_REQUEST_PRIOR_TO_RAMP_DATE_ERROR,
  DOCKET_SWITCH_REVIEW_REQUEST_FUTURE_DATE_ERROR
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { add, format } from 'date-fns';

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

  const setup = (props) =>
    render(<DocketSwitchReviewRequestForm {...defaults} {...props} />);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = setup();

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
    setup();

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
    setup();
    expect(onCancel).not.toHaveBeenCalled();
    expect(screen.getByText('Grant all issues')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation for receipt date', () => {
    const priorToRampReceiptDate = '2017-10-31';
    const futureDate = format(add(new Date(), { days: 5 }), 'yyyy-MM-dd');

    it('throws error for prior-to-RAMP receipt date', async () => {
      render(<DocketSwitchReviewRequestForm {...defaults} />);

      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: priorToRampReceiptDate },
      });
      // Use blur to trigger value to be touched
      await fireEvent.blur(screen.getByLabelText(/receipt date/i));

      await waitFor(() => {
        expect(
          screen.getByText(DOCKET_SWITCH_REVIEW_REQUEST_PRIOR_TO_RAMP_DATE_ERROR)
        ).toBeInTheDocument();
      });

    });

    it('throws error for receipt date in future', async () => {
      render(<DocketSwitchReviewRequestForm {...defaults} />);

      await fireEvent.change(screen.getByLabelText(/receipt date/i), {
        target: { value: futureDate },
      });
      // Use blur to trigger value to be touched
      await fireEvent.blur(screen.getByLabelText(/receipt date/i));

      await waitFor(() => {
        expect(
          screen.getByText(DOCKET_SWITCH_REVIEW_REQUEST_FUTURE_DATE_ERROR)
        ).toBeInTheDocument();
      });
    });
  });

  describe('form validation for all granted issues', () => {
    const receiptDate = '2020-10-01';

    it('fires onSubmit with correct values', async () => {
      setup();

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

    it('fires onSubmit with correct values', async () => {
      setup();

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

  describe('default values', () => {
    let defaultValues;

    beforeEach(() => {
      defaultValues = {
        receiptDate: '2021-02-15',
        disposition: 'granted',
        docketType: 'hearing',
      };
    });

    describe('full grant', () => {
      it('populates with default values', async () => {
        const { container } = setup({ defaultValues });

        expect(container).toMatchSnapshot();

        const submit = screen.getByRole('button', { name: /Continue/i });

        expect(submit).toBeEnabled();
        await userEvent.click(submit);
        await waitFor(() => {
          expect(onSubmit).toHaveBeenLastCalledWith(
            expect.objectContaining({
              disposition: defaultValues.disposition,
              docketType: defaultValues.docketType,
              issueIds: issues.map((item) => `${item.id}`),
              // receiptDate: new Date(defaultValues.receiptDate), // commented due to TZ weirdness
            })
          );
        });
      });
    });

    describe('partial grant', () => {
      it('populates with default values', async () => {
        const newDefaults = {
          ...defaultValues,
          disposition: 'partially_granted',
          issueIds: [2],
        };
        const { container } = setup({
          defaultValues: newDefaults,
        });

        expect(container).toMatchSnapshot();

        const submit = screen.getByRole('button', { name: /Continue/i });

        expect(submit).toBeEnabled();
        await userEvent.click(submit);
        await waitFor(() => {
          expect(onSubmit).toHaveBeenLastCalledWith(
            expect.objectContaining({
              disposition: newDefaults.disposition,
              docketType: newDefaults.docketType,
              issueIds: ['2'],
              // receiptDate: new Date(defaultValues.receiptDate), // commented due to TZ weirdness
            })
          );
        });
      });
    });
  });
});
