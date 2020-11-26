import React from 'react';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';

import { EditClaimLabelModal } from 'app/intakeEdit/components/EditClaimLabelModal';
import { select } from 'glamor';

describe('EditClaimLabelModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaults = { onCancel, onSubmit, selectedEpCode: '040HDENR' };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<EditClaimLabelModal {...defaults} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<EditClaimLabelModal {...defaults} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should fire cancel event', async () => {
    render(<EditClaimLabelModal {...defaults} />);

    await userEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  it('defaults to the current claim label', async () => {
    render(<EditClaimLabelModal {...defaults} />);

    // Preselected, the code should show on screen
    expect(screen.getByText(defaults.selectedEpCode)).toBeInTheDocument();
  });

  describe('correctly filters by EP code family', () => {
    it('displays only codes from 040 family', async () => {
      render(<EditClaimLabelModal {...defaults} />);

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).toBeTruthy();
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).not.toBeTruthy();
    });

    it('displays only codes from 030 family', async () => {
      render(<EditClaimLabelModal {...defaults} selectedEpCode="030HLRFID" />);

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).toBeTruthy();
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).not.toBeTruthy();
    });

    it('displays only codes from 930 family', async () => {
      render(
        <EditClaimLabelModal {...defaults} selectedEpCode="930AHCNRLPMC" />
      );

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).toBeTruthy();
    });
  });

  describe('validation', () => {
    it('disables the submit until a new code has been chosen', async () => {
      render(<EditClaimLabelModal {...defaults} />);

      const submit = screen.getByRole('button', { name: /continue/i });
      const dropdown = screen.getByLabelText(
        /select the correct ep claim label/i
      );

      expect(submit).toBeDisabled();

      userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      await selectEvent.select(dropdown, '040BDERPMC');

      expect(submit).not.toBeDisabled();
    });
  });

  describe('submission', () => {
    it('submits the correct values', async () => {
      render(<EditClaimLabelModal {...defaults} />);

      const newCode = '040BDERPMC';

      const submit = screen.getByRole('button', { name: /continue/i });
      const dropdown = screen.getByLabelText(
        /select the correct ep claim label/i
      );

      await selectEvent.select(dropdown, newCode);
      userEvent.click(submit);

      expect(onSubmit).toHaveBeenCalledWith({ oldCode: defaults.selectedEpCode, newCode });
    });
  });

});
