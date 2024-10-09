import React from 'react';
import { axe } from 'jest-axe';
import { act } from 'react-dom/test-utils';
import { sprintf } from 'sprintf-js';
import { screen, render, waitFor, fireEvent } from '@testing-library/react';

import BENEFIT_TYPES from '../../../../constants/BENEFIT_TYPES';
import COPY from '../../../../COPY';
import BenefitType from '../../../../app/intake/components/BenefitType';

const defaultProps = {
  value: null,
  onChange: jest.fn(),
  register: jest.fn(),
  formName: 'higherLevelReview',
  userCanSelectVha: false,
  featureToggles: { vhaClaimReviewEstablishment: true },
};

const vhaTooltipText = sprintf(COPY.INTAKE_VHA_CLAIM_REVIEW_REQUIREMENT, COPY.VHA_BENEFIT_EMAIL_ADDRESS);
const penAndCompTooltipText = sprintf(COPY.INTAKE_REMOVE_COMP_AND_PEN);

const renderBenefitType = (props) => {
  return render(<BenefitType {...props} />);
};

const getVhaRadioOption = () => screen.getByRole('radio', { name: BENEFIT_TYPES.vha });
const getCompRadioOption = () => screen.getByRole('radio', { name: BENEFIT_TYPES.compensation });
const getPenRadioOption = () => screen.getByRole('radio', { name: BENEFIT_TYPES.pension });

const getVhaOptionTooltip = () => {
  return screen.getByRole(
    'tooltip',
    { hidden: true }
  );
};

const hoverOverRadioOption = (option) => {
  act(() => {
    fireEvent(
      option,
      new MouseEvent('mouseenter', {
        bubbles: true
      })
    );
  });
};

describe('BenefitType', () => {
  it('passes a11y', async () => {
    const { container } = renderBenefitType(defaultProps);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('On a Higher Level Review form', () => {
    describe('when the user is not a VHA staff member', () => {
      const props = { ...defaultProps };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is disabled', () => {
        expect(getVhaRadioOption()).toBeDisabled();
      });

      it('A tooltip appears whenever VHA option is hovered over', async () => {
        hoverOverRadioOption(getVhaRadioOption());

        await waitFor(() => {
          expect(getVhaOptionTooltip()).toBeVisible();
        });
      });
    });

    describe('when remove comp and pen intake is disabled', () => {
      const props = {
        ...defaultProps,
        featureToggles: { removeCompAndPenIntake: false }

      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getCompRadioOption()).not.toBeDisabled();
        expect(getPenRadioOption()).not.toBeDisabled();
      });

      it('Tooltip does not appear whenever Compensation option is hovered over', () => {
        hoverOverRadioOption(getCompRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });

      it('Tooltip does not appear whenever Pension option is hovered over', () => {
        hoverOverRadioOption(getPenRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });
    });

    describe('when remove comp and pen intake is enabled', () => {
      const props = {
        ...defaultProps,
        featureToggles: { removeCompAndPenIntake: true }

      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getCompRadioOption()).toBeDisabled();
        expect(getPenRadioOption()).toBeDisabled();
      });

      it('Tooltip appear whenever Comp and Pen option is hovered over', async () => {

        await waitFor(() => {
          const toolTipElements = screen.getAllByRole('tooltip');

          toolTipElements.forEach((toolTipElement) => {
            if (toolTipElement.id === 'tooltip-pension' || toolTipElement.id === 'tooltip-compensation') {
              expect(toolTipElement).toBeInTheDocument();
              expect(toolTipElement).toHaveTextContent(penAndCompTooltipText);
            }
          });
        });
      });
    });

    describe('when the user is a VHA staff member with feature toggle disabled on Higher Level Review Form', () => {
      const props = {
        ...defaultProps,
        featureToggles: { vhaClaimReviewEstablishment: false }

      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getVhaRadioOption()).not.toBeDisabled();
      });

      it('Tooltip does not appear whenever VHA option is hovered over', () => {
        hoverOverRadioOption(getVhaRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });
    });

    describe('when the user is a VHA staff member', () => {
      const props = {
        ...defaultProps,
        userCanSelectVha: true
      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getVhaRadioOption()).not.toBeDisabled();
      });

      it('Tooltip does not appear whenever VHA option is hovered over', () => {
        hoverOverRadioOption(getVhaRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });
    });
  });

  describe('On a Supplemental Claim form', () => {
    describe('when the user is not a VHA staff member', () => {
      const props = {
        ...defaultProps,
        formName: 'supplementalClaim'
      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is disabled', () => {
        expect(getVhaRadioOption()).toBeDisabled();
      });

      it('Tooltip appears whenever VHA option is hovered over', async () => {
        hoverOverRadioOption(getVhaRadioOption());

        await waitFor(() => {
          expect(getVhaOptionTooltip()).toBeVisible();
        });
      });
    });

    describe('when the user is a VHA staff member with feature toggle disabled on Supplemental Claim Form', () => {
      const props = {
        ...defaultProps,
        featureToggles: { vhaClaimReviewEstablishment: false }

      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getVhaRadioOption()).not.toBeDisabled();
      });

      it('Tooltip does not appear whenever VHA option is hovered over', () => {
        hoverOverRadioOption(getVhaRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });
    });

    describe('when the user is a VHA staff member', () => {
      const props = {
        ...defaultProps,
        formName: 'supplementalClaim',
        userCanSelectVha: true
      };

      beforeEach(() => {
        renderBenefitType(props);
      });

      it('The "Veterans Health Administration" option is enabled', () => {
        expect(getVhaRadioOption()).not.toBeDisabled();
      });

      it('A tooltip does not appear whenever VHA option is hovered over', () => {
        hoverOverRadioOption(getVhaRadioOption());

        expect(
          screen.queryByText(vhaTooltipText)
        ).not.toBeInTheDocument();
      });
    });
  });
});
