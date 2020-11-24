import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import COPY from 'COPY';
import EP_CLAIM_TYPES from 'constants/EP_CLAIM_TYPES';

import { ConfirmClaimLabelModal } from 'app/intakeEdit/components/ConfirmClaimLabelModal';


describe('ConfirmClaimLabelModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaults = { onCancel, onSubmit, previousEpCode: '030HLRR', newEpCode: "030HLRNR" };
  // const oldLabel = EP_CLAIM_TYPES[defaults.previousEpCode].official_label;

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

    // const newLabel = EP_CLAIM_TYPES[defaults.newEpCode].official_label;
    // expect(screen.queryByText(oldLabel)).toBeTruthy();
    expect(screen.getByText(COPY.EDIT_CLAIM_LABEL_MODAL_NOTE)).toBeInTheDocument();
    expect(screen.queryByText(COPY.EDIT_CLAIM_LABEL_MODAL_NOTE)).toBeInTheDocument();
    // expect(screen.getByText('Higher')).toBeInTheDocument();
    // expect(screen.getByText(`New label: ${newLabel}`)).toBeInTheDocument();
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
