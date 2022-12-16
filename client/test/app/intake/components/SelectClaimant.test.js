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

describe('SelectClaimant', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setVeteranIsNotClaimant = jest.fn();

  const defaultProps = {
    formType: 'appeal',
    relationships: defaultRelationships,
    featureToggles: { hlrScUnrecognizedClaimants: true },
    setVeteranIsNotClaimant
  };

  const setupDefault = (props = { ...defaultProps }) => {
    return render(<SelectClaimant {...props} />);
  };

  const renderSelectClaimant = (
    props = {
      toggled: false,
      formType: '',
    }
  ) => {
    return render(
      <SelectClaimant
        isVeteranDeceased
        relationships={defaultRelationships}
        benefitType={props.benefitType}
        formType={props.formType}
        veteranIsNotClaimant={props.veteranIsNotClaimant}
        setVeteranIsNotClaimant={setVeteranIsNotClaimant}
        featureToggles={props.featureToggles}
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

  describe('with formType', () => {
    const featureToggles = { hlrScUnrecognizedClaimants: true };
    const setupProps = { toggled: true, featureToggles };

    it('renders correctly', () => {
      const { container } = renderSelectClaimant(setupProps);

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = renderSelectClaimant(setupProps);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe("with formType 'appeal'", () => {
    const formType = { formType: 'appeal' };
    const featureToggles = { hlrScUnrecognizedClaimants: true };
    const setupProps = { ...formType, toggled: true, featureToggles };

    it('disables different-claimant-option_false radio button and does NOT fire off setVeteranIsNotClaimant', () => {
      renderSelectClaimant(setupProps);

      const radioNo = screen.getByRole('radio', { name: /no/i });

      expect(radioNo).toBeEnabled();
      expect(setVeteranIsNotClaimant).toBeCalledTimes(0);
    });

    it('renders deceasedVeteranAlert', () => {
      renderSelectClaimant({ ...setupProps, veteranIsNotClaimant: false });

      const alert = screen.getByRole('alert');

      expect(alert).toBeInTheDocument();
    });

    describe('nonVeteranClaimants enabled', () => {
      it('renders correctly', async () => {
        // Component only differs when veteranIsNotClaimant is set
        const veteranIsNotClaimant = true;
        const { container } = setupDefault({
          ...defaultProps,
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
          screen.queryByText(COPY.SELECT_NON_LISTED_CLAIMANT_LABEL)
        ).toBeInTheDocument();
        expect(
          screen.queryByRole('radio', { name: /claimant not listed/i })
        ).toBeInTheDocument();

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setupDefault({ ...defaultProps });

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });
    });
  });

  describe("with formType not 'appeal'", () => {
    const featureToggles = { hlrScUnrecognizedClaimants: true };
    const setupProps = { toggled: true, featureToggles };

    it('disables different-claimant-option_false radio button & fires off setVeteranIsNotClaimant', () => {
      renderSelectClaimant(setupProps);

      const radioNo = screen.getByRole('radio', { name: /no/i });

      expect(radioNo).toBeDisabled();
      expect(setVeteranIsNotClaimant).toBeCalled();
    });
  });

  describe("with formType 'higher_level_review'", () => {
    const formType = 'higher_level_review';
    const veteranIsNotClaimant = true;

    it('short label, no "Claimant Not Listed" option and payee code dropdown for one of first 3 benefit types', () => {
      const benefitType = 'pension';
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType };

      renderSelectClaimant(setupProps);

      expect(screen.queryByText(COPY.SELECT_CLAIMANT_LABEL)).toBeInTheDocument();
      expect(screen.queryByText(COPY.SELECT_NON_LISTED_CLAIMANT_LABEL)).not.toBeInTheDocument();
      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).not.toBeInTheDocument();
      expect(screen.queryByText('What is the payee code for this claimant?')).toBeInTheDocument();
    });

    it('long label, "Claimant Not Listed" option, no payee code dropdown if other than first 3 benefit types', () => {
      const benefitType = 'insurance';
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType };

      renderSelectClaimant(setupProps);

      expect(screen.queryByText(COPY.SELECT_NON_LISTED_CLAIMANT_LABEL)).toBeInTheDocument();
      expect(screen.queryByText(COPY.SELECT_CLAIMANT_LABEL)).not.toBeInTheDocument();
      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).toBeInTheDocument();
      expect(screen.queryByText('What is the payee code for this claimant?')).not.toBeInTheDocument();
    });

    it('shows feature toggle is functioning correctly', () => {
      const featureToggles = { hlrScUnrecognizedClaimants: false };
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType: 'education', featureToggles };

      renderSelectClaimant(setupProps);

      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).not.toBeInTheDocument();
    });
  });

  describe("with formType 'supplemental_claim'", () => {
    const formType = 'supplemental_claim';
    const veteranIsNotClaimant = true;

    it('short label, no "Claimant Not Listed" option and payee code dropdown for one of first 3 benefit types', () => {
      const benefitType = 'fiduciary';
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType };

      renderSelectClaimant(setupProps);

      expect(screen.queryByText(COPY.SELECT_CLAIMANT_LABEL)).toBeInTheDocument();
      expect(screen.queryByText(COPY.SELECT_NON_LISTED_CLAIMANT_LABEL)).not.toBeInTheDocument();
      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).not.toBeInTheDocument();
      expect(screen.queryByText('What is the payee code for this claimant?')).toBeInTheDocument();
    });

    it('long label, "Claimant Not Listed" option, no payee code dropdown if other than first 3 benefit types', () => {
      const benefitType = 'loan_guaranty';
      const featureToggles = { hlrScUnrecognizedClaimants: true };
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType, featureToggles };

      renderSelectClaimant(setupProps);

      expect(screen.queryByText(COPY.SELECT_NON_LISTED_CLAIMANT_LABEL)).toBeInTheDocument();
      expect(screen.queryByText(COPY.SELECT_CLAIMANT_LABEL)).not.toBeInTheDocument();
      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).toBeInTheDocument();
      expect(screen.queryByText('What is the payee code for this claimant?')).not.toBeInTheDocument();
    });

    it('shows feature toggle is functioning correctly', () => {
      const benefitType = 'loan_guaranty';
      const featureToggles = { hlrScUnrecognizedClaimants: false };
      const setupProps = { ...defaultProps, formType, veteranIsNotClaimant, benefitType, featureToggles };

      renderSelectClaimant(setupProps);

      expect(screen.queryByRole('radio', { name: /claimant not listed/i })).not.toBeInTheDocument();
    });
  });
});
