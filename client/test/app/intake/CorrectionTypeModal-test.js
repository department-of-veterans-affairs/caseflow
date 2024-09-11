import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import CorrectionTypeModal from '../../../app/intake/components/CorrectionTypeModal';
import { sample1 } from './testData';
import { newProps } from './testHelpers';

describe('CorrectionTypeModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  const defaultProps = {
    formType: formType,
    intakeData: intakeData,
    onSkip: () => null,
  };

  const setup = (props) => {
    return render(
      <CorrectionTypeModal
        {...defaultProps} {...props}
      />
    );
  }

  describe('renders', () => {
    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Next')).toBeInTheDocument();
    });

    it('renders with new props', async () => {
      setup(newProps);

      const cancelBtn = await screen.findByText('cancel');
      const skipBtn = await screen.findByText('skip');
      const submitBtn = await screen.findByText('submit');

      expect(cancelBtn.textContent).toBe('cancel');
      expect(skipBtn.textContent).toBe('skip');
      expect(submitBtn.textContent).toBe('submit');
    });

    it('skip button only with onSkip prop', () => {
      const {container, rerender}=render(<CorrectionTypeModal
        formType={formType}
        intakeData={intakeData}
        />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      rerender(<CorrectionTypeModal
        formType={formType}
        intakeData={intakeData}
        onSkip={() => null}
        />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', () => {
      const { rerender } = render(<CorrectionTypeModal
         formType={formType}
         intakeData={intakeData}
         />);

      let submitBtn = screen.getByRole('button', { name: /Next/i });

      expect(submitBtn).toBeDisabled();

      rerender(<CorrectionTypeModal
        formType={formType}
        intakeData={intakeData}
        correctionType={'control'}
        />);

        submitBtn = screen.getByRole('button', { name: /Next/i });
        const controlRadioButton = screen.getByRole('radio', { name: 'Control' });
        userEvent.click(controlRadioButton);
        expect(submitBtn).not.toBeDisabled();
    });
  });
});
