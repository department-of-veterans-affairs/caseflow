import React from 'react';
import {
  screen,
  render
} from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

import { SelectClaimant } from 'app/intake/components/SelectClaimant';

const defaultRelationships = [{
  value: 'CLAIMANT_WITH_PVA_AS_VSO',
  displayText: 'Bob Vance, Spouse',
  defaultPayeeCode: '10'
}, {
  value: '1129318238',
  displayText: 'Cathy Smith, Child',
  defaultPayeeCode: '11'
}];

const defaultFeatureToggles = {
  attorneyFees: false,
  establishFiduciaryEps: false,
  deceasedAppellants: false
};

describe('SelectClaimant', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setVeteranisNotClaimant = jest.fn();

  const setupDefault = () => {
    return render(
      <SelectClaimant
        relationships={defaultRelationships}
        featureToggles={defaultFeatureToggles}
      />);
  };

  const setupDeceasedAppellants = (props = {
    toggled: false, formType: '' }) => {

    return render(
      <SelectClaimant
        isVeteranDeceased
        featureToggles={{ ...defaultFeatureToggles,
          deceasedAppellants: props.toggled }}
        relationships={defaultRelationships}
        formType={props.formType}
        veteranIsNotClaimant={props.veteranIsNotClaimant}
        setVeteranIsNotClaimant={setVeteranisNotClaimant}
      />);
  };

  describe('with default value props', () => {
    it('renders correctly', () => {
      const { container } = setupDefault();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setupDefault();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe("with formType 'appeal'", () => {
    const formType = { formType: 'appeal' };

    describe('deceasedAppellants toggled OFF', () => {
      it('renders correctly', () => {
        const { container } = setupDeceasedAppellants(formType);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDeceasedAppellants(formType);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('disables different-claimant-option_false radio button and fires off setVeteranIsNotClaimant', () => {
        setupDeceasedAppellants(formType);

        const radioNo = screen.getByRole('radio', { name: /no/i });

        expect(radioNo).toBeDisabled();
        expect(setVeteranisNotClaimant).toHaveBeenCalled();
      });
    });

    describe('deceasedAppellants toggled ON', () => {
      const setupProps = { ...formType, toggled: true };

      it('renders correctly', () => {
        const { container } = setupDeceasedAppellants(setupProps);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDeceasedAppellants(setupProps);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('disables different-claimant-option_false radio button and does NOT fire off setVeteranIsNotClaimant', () => {
        setupDeceasedAppellants(setupProps);

        const radioNo = screen.getByRole('radio', { name: /no/i });

        expect(radioNo).toBeEnabled();
        expect(setVeteranisNotClaimant).toBeCalledTimes(0);
      });

      it('renders deceasedVeteranAlert', () => {
        setupDeceasedAppellants({...setupProps, veteranIsNotClaimant: false});

        const alert = screen.getByRole('alert');

        expect(alert).toBeInTheDocument();
      });
    });
  });

  describe("with formType not 'appeal'", () => {
    describe('deceasedAppellants toggled OFF', () => {
      it('renders correctly', () => {
        const { container } = setupDeceasedAppellants();

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDeceasedAppellants();

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('does disable different-claimant-option_false radio button and fires off setVeteranIsNotClaimant', () => {
        setupDeceasedAppellants();

        const radioNo = screen.getByRole('radio', { name: /no/i });

        expect(radioNo).toBeDisabled();
        expect(setVeteranisNotClaimant).toHaveBeenCalled();
      });
    });

    describe('deceasedAppellants toggled ON', () => {
      const setupProps = { toggled: true };

      it('renders correctly', () => {
        const { container } = setupDeceasedAppellants(setupProps);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDeceasedAppellants(setupProps);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('disables different-claimant-option_false radio button & fires off setVeteranIsNotClaimant', () => {
        setupDeceasedAppellants(setupProps);

        const radioNo = screen.getByRole('radio', { name: /no/i });

        expect(radioNo).toBeDisabled();
        expect(setVeteranisNotClaimant).toBeCalled();
      });
    });
  });
});
