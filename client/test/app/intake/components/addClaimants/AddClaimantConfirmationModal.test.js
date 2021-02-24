import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

import COPY from 'app/../COPY';

import {
  AddClaimantConfirmationModal,
  shapeAddressBlock,
} from 'app/intake/addClaimant/AddClaimantConfirmationModal';
import {
  individualClaimant,
  individualPoa,
  organizationClaimant,
} from 'test/data/intake/claimants';

describe('AddClaimantConfirmationModal', () => {
  const onConfirm = jest.fn();
  const onCancel = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onConfirm, onCancel, claimant: individualClaimant };
  const setup = (props) => {
    return render(<AddClaimantConfirmationModal {...defaults} {...props} />);
  };

  describe('without POA', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('with POA', () => {
    it('renders correctly', () => {
      const { container } = setup({ poa: individualPoa });

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('individual claimant', () => {
    describe('missing last name', () => {
      const claimant = { ...defaults.claimant, lastName: '' };

      it('shows alert', () => {
        const { container } = setup({ claimant });

        expect(
          screen.getByText(COPY.ADD_CLAIMANT_CONFIRM_MODAL_LAST_NAME_ALERT)
        ).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });

      it('passes a11y', async () => {
        const { container } = setup({ claimant });

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });
    });
  });

  describe('organization claimant', () => {
    const claimant = organizationClaimant;

    it('renders correctly', () => {
      const { container } = setup({ claimant });

      expect(container).toMatchSnapshot();
    });
  });

  it('fires onCancel', async () => {
    setup();

    const cancelButton = screen.getByRole('button', {
      name: /cancel and edit/i,
    });

    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(cancelButton);
    expect(onCancel).toHaveBeenCalled();
  });

  it('fires onConfirm', async () => {
    setup();

    const confirmButton = screen.getByRole('button', { name: /confirm/i });

    expect(onConfirm).not.toHaveBeenCalled();

    await userEvent.click(confirmButton);
    expect(onConfirm).toHaveBeenCalled();
  });
});

describe('shapeAddressBlock', () => {
  const addressObj = {
    address1: '123 Main St',
    address2: 'Suite A',
    city: 'San Francisco',
    state: 'CA',
    zip: '94123',
  };

  describe('with newly entered entity', () => {
    const entity = {
      relationship: 'other',
      partyType: 'individual',
      listedAttorney: {
        label: 'Name not listed',
        value: 'not_listed'
      },
      firstName: 'Jane',
      lastName: 'Doe',
      ...addressObj,
    };

    it('returns correct data', () => {
      expect(shapeAddressBlock(entity)).toMatchObject({ ...entity });
    });
  });

  describe('with existing attorney for claimant', () => {
    const entity = {
      relationship: 'attorney',
      partyType: 'individual',
      listedAttorney: {
        label: 'Jane Doe',
        ...addressObj,
      },
    };

    it('returns correct data', () => {
      expect(shapeAddressBlock(entity)).toMatchObject({ ...entity });
    });
  });

  describe('with existing attorney for claimant POA', () => {
    const entity = {
      listedAttorney: {
        label: 'Jane Doe',
        ...addressObj,
      },
    };

    it('returns correct data', () => {
      expect(shapeAddressBlock(entity)).toMatchObject({ ...entity });
    });
  });
});
