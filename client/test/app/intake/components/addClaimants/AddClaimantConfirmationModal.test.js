import React from 'react';
import {
  screen,
  render,
  fireEvent,
  within,
  act,
  waitFor,
} from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';

import COPY from 'app/../COPY';

import { AddClaimantConfirmationModal } from 'app/intake/addClaimant/AddClaimantConfirmationModal';

describe('AddClaimantConfirmationModal', () => {
  const onConfirm = jest.fn();
  const onCancel = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onConfirm, onCancel };
  const setup = () => {
    return render(<AddClaimantConfirmationModal {...defaults} />);
  };

  describe('without POA', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });
  });

  describe('with POA', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });
  });

  it('fires onCancel', async () => {
    setup();

    const cancelButton = screen.getByRole('button', { name: /cancel and edit/i });

    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(cancelButton);
    expect(onCancel).not.toHaveBeenCalled();
  });

});
