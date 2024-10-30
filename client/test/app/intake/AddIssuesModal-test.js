/* eslint-disable max-len */
import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import AddIssuesModal from '../../../app/intake/components/AddIssuesModal';
import { sample1 } from './testData';
import { testRenderingWithNewProps } from '../../helpers/testHelpers';

describe('AddIssuesModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureToggles = { mstIdentification: true };

  const defaultProps = {
    formType: formType,
    intakeData: intakeData,
    onSkip: () => null,
    featureToggles: featureToggles,
  };

  const setup = (props) => {
    return render(
      <AddIssuesModal
        {...defaultProps} {...props}
      />
    );
  }

  describe('renders', () => {
    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Next')).toBeInTheDocument();
    });

    it('renders with new props', async () => {
      testRenderingWithNewProps(setup);
    });

    it('skip button only with onSkip prop', () => {
      const {container, rerender} = render(<AddIssuesModal
        featureToggles={featureToggles}
        formType={formType}
        intakeData={intakeData}
        />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      rerender(<AddIssuesModal
        featureToggles={featureToggles}
        formType={formType}
        intakeData={intakeData}
        onSkip={() => null}
        />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', () => {
      const { rerender } = render(<AddIssuesModal
        featureToggles={featureToggles}
        formType={formType}
        intakeData={intakeData}
        />);

        let submitBtn = screen.getByRole('button', { name: /Next/i });
        expect(submitBtn).toBeDisabled();

      rerender(<AddIssuesModal
        featureToggles={featureToggles}
        formType={formType}
        intakeData={intakeData}
        selectedContestableIssueIndex={'2'}
        />);

      // We need to find element again, or it won't appear updated
      submitBtn = screen.getByRole('button', { name: /Next/i });
      const ptsdRadioButton = screen.getByRole('radio', { name: 'PTSD' });
      userEvent.click(ptsdRadioButton);
      expect(submitBtn).not.toBeDisabled();
    });
  });
});
