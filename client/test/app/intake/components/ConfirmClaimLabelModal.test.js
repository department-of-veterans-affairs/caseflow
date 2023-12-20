import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import COPY from 'COPY';

import { ConfirmClaimLabelModal } from 'app/intakeEdit/components/ConfirmClaimLabelModal';

describe('ConfirmClaimLabelModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaults = { onCancel, onSubmit, previousEpCode: '030HLRR', newEpCode: "030HLRNR" };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<ConfirmClaimLabelModal {...defaults} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<ConfirmClaimLabelModal {...defaults} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should fire cancel event', async () => {
    render(<ConfirmClaimLabelModal {...defaults} />);

    await userEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  it('shows the previous and new selected claim label', async () => {
    render(<ConfirmClaimLabelModal {...defaults} />);
    expect(screen.getByText((/previous label: higher-level review rating*/i))).toBeInTheDocument();
    expect(screen.getByText((/new label: higher-level review non-rating*/i))).toBeInTheDocument();
    expect(screen.getByText(COPY.CONFIRM_CLAIM_LABEL_MODAL_BODY)).toBeInTheDocument();
  });

  describe('submission', () => {
    it('submits the correct values', async () => {
      render(<ConfirmClaimLabelModal {...defaults} />);

      const submit = screen.getByRole('button', { name: /confirm/i });

      userEvent.click(submit);

      expect(onSubmit).toHaveBeenCalledWith({ previousEpCode: defaults.previousEpCode, newEpCode: defaults.newEpCode });
    });
  });

});
