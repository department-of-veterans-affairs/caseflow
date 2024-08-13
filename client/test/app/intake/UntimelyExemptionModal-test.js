import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { reducer, generateInitialState } from '../../../app/intake';

import ReduxBase from '../../../app/components/ReduxBase';
import UntimelyExemptionModal from '../../../app/intake/components/UntimelyExemptionModal';
import { sample1 } from './testData';

describe('UntimelyExemptionModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const currentIssue = sample1.currentIssue1;

  // eslint-disable-next-line react/prop-types
  const wrappingComponent = ({ children }) => (
    <ReduxBase initialState={generateInitialState()} reducer={reducer} analyticsMiddlewareArgs={['intake']}>
      {children}
    </ReduxBase>
  );

  const defaultProps = {
    formType,
    intakeData,
    currentIssue,
    onSubmit: () => null,
    onCancel: () => null,
    onSkip: () => null,
  };

  const setup = (props) => {
    return render(
      <UntimelyExemptionModal
        {...defaultProps} {...props}
      />,
      {
        wrapper: wrappingComponent,
      }
    );
  }

  describe('renders', () => {
    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Add this issue')).toBeInTheDocument();
    });
    it('renders with new props', async () => {
      const newProps = {
        cancelText: 'cancel',
        skipText: 'skip',
        submitText: 'submit'
      };

      setup(newProps);

      const cancelBtn = await screen.findByText('cancel');
      const skipBtn = await screen.findByText('skip');
      const submitBtn = await screen.findByText('submit');

      expect(cancelBtn.textContent).toBe('cancel');
      expect(skipBtn.textContent).toBe('skip');
      expect(submitBtn.textContent).toBe('submit');
    });

    it('skip button only with onSkip prop', () => {
      const {container, rerender}=render(<UntimelyExemptionModal
        formType={formType}
        intakeData={intakeData}
        currentIssue={currentIssue}
        onSubmit={() => null}
        onCancel={() => null}
        />,
        { wrapper: wrappingComponent });

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      rerender(<UntimelyExemptionModal
        formType={formType}
        intakeData={intakeData}
        currentIssue={currentIssue}
        onSubmit={() => null}
        onCancel={() => null}
        onSkip={() => null}
        />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', () => {
      const { rerender } = render(<UntimelyExemptionModal
        {...defaultProps}
        />,
        { wrapper: wrappingComponent });

        let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
        expect(submitBtn).toBeDisabled();

        rerender(<UntimelyExemptionModal
          {...defaultProps}
          untimelyExemption={'true'}
          />);

        submitBtn = screen.getByRole('button', { name: /Add this issue/i });
        const yesRadio = screen.getByRole('radio', { name: /Yes/i });
        userEvent.click(yesRadio);
        expect(submitBtn).not.toBeDisabled();
    });
  });
});
