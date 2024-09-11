import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';

import UnidentifiedIssuesModal from '../../../app/intake/components/UnidentifiedIssuesModal';
import { sample1 } from './testData';
import { newProps } from '../../helpers/testHelpers';
describe('UnidentifiedIssuesModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  describe('renders', () => {

    const defaultProps = {
      formType: formType,
      intakeData: intakeData,
      onSkip: () => null,
    };

    const setup = (props) => {
      return render(
        <UnidentifiedIssuesModal
          {...defaultProps} {...props}
        />
      );
    }
    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Add this issue')).toBeInTheDocument();

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
      const {container, rerender} = render(<UnidentifiedIssuesModal
        formType={formType}
        intakeData={intakeData} />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      rerender(<UnidentifiedIssuesModal formType={formType} intakeData={intakeData} onSkip={() => null} />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', async () => {
      const {container, rerender} = render(<UnidentifiedIssuesModal
        formType={formType}
        intakeData={intakeData} />);

      let submitBtn = container.querySelector('.cf-modal-controls .add-issue');

      expect(submitBtn).toBeDisabled();

      rerender(
        <UnidentifiedIssuesModal
          formType={formType}
          intakeData={intakeData}
          description={'blah blah'}
          decisionDate={'2022-01-01'}
          notes={'Some notes'}
          verifiedUnidentifiedIssue={true}
        />
      );

      let inputElement = container.querySelector('input[id="Transcribe the issue as it\'s written on the form"]');
      fireEvent.change(inputElement, { target: { value: 'blah blah' } });

      submitBtn = container.querySelector('.cf-modal-controls .add-issue');
      expect(submitBtn).not.toBeDisabled();
    });
  });
});
