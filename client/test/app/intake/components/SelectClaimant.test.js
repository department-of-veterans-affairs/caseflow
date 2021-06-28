import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';

import COPY from 'app/../COPY';

import { SelectClaimant } from 'app/intake/components/SelectClaimant';

const defaultRelationships = [
  {
    value: 'CLAIMANT_WITH_PVA_AS_VSO',
    displayText: 'Bob Vance, Spouse',
    defaultPayeeCode: '10',
  },
  {
    value: '1129318238',
    displayText: 'Cathy Smith, Child',
    defaultPayeeCode: '11',
  },
];

const defaultFeatureToggles = { deceasedAppellants: false };

describe('SelectClaimant', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setVeteranIsNotClaimant = jest.fn();

  const defaultProps = {
    formType: 'appeal',
    relationships: defaultRelationships,
    featureToggles: defaultFeatureToggles,
    setVeteranIsNotClaimant,
  };

  const setupDefault = (props = { ...defaultProps }) => {
    return render(<SelectClaimant {...props} />);
  };

  const setupDeceasedAppellants = (
    props = {
      toggled: false,
      formType: '',
    }
  ) => {
    return render(
      <SelectClaimant
        isVeteranDeceased
        featureToggles={{
          ...defaultFeatureToggles,
          deceasedAppellants: props.toggled,
        }}
        relationships={defaultRelationships}
        formType={props.formType}
        veteranIsNotClaimant={props.veteranIsNotClaimant}
        setVeteranIsNotClaimant={setVeteranIsNotClaimant}
      />
    );
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
        expect(setVeteranIsNotClaimant).toHaveBeenCalled();
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
        expect(setVeteranIsNotClaimant).toBeCalledTimes(0);
      });

      it('renders deceasedVeteranAlert', () => {
        setupDeceasedAppellants({ ...setupProps, veteranIsNotClaimant: false });

        const alert = screen.getByRole('alert');

        expect(alert).toBeInTheDocument();
      });
    });

    describe('nonVeteranClaimants enabled', () => {
      const featureToggles = {
        ...defaultFeatureToggles,
      };

      it('renders correctly', async () => {
        // Component only differs when veteranIsNotClaimant is set
        const veteranIsNotClaimant = true;
        const { container } = setupDefault({
          ...defaultProps,
          featureToggles,
          veteranIsNotClaimant,
        });

        // Ensure it's rendering the additional content
        expect(
          screen.queryByText(COPY.CLAIMANT_NOT_FOUND_START)
        ).not.toBeInTheDocument();
        expect(
          screen.queryByText(COPY.CLAIMANT_NOT_FOUND_END)
        ).not.toBeInTheDocument();

        expect(
          screen.queryByText(COPY.SELECT_CLAIMANT_LABEL)
        ).toBeInTheDocument();
        expect(
          screen.queryByRole('radio', { name: /claimant not listed/i })
        ).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDefault({ ...defaultProps, featureToggles });

        const results = await axe(container);

        expect(results).toHaveNoViolations();
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
        expect(setVeteranIsNotClaimant).toHaveBeenCalled();
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
        expect(setVeteranIsNotClaimant).toBeCalled();
      });
    });
  });
});
