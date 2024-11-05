import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';

import UnidentifiedIssuesModal from '../../../app/intake/components/UnidentifiedIssuesModal';
import { sample1 } from './testData';
import { testRenderingWithNewProps } from '../../helpers/testHelpers';
describe('UnidentifiedIssuesModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  describe('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(
        <UnidentifiedIssuesModal
        formType={formType}
        intakeData={intakeData}
        onSkip={() => null} />
      );
    }
    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Add this issue')).toBeInTheDocument();

    });
    it('renders with new props', async () => {
      testRenderingWithNewProps(setup);
    });

    it('skip button only with onSkip prop', () => {
      const wrapper = mount(<UnidentifiedIssuesModal
        formType={formType}
        intakeData={intakeData} />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      rerender(<UnidentifiedIssuesModal formType={formType} intakeData={intakeData} onSkip={() => null} />);

      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(<UnidentifiedIssuesModal formType={formType}
        intakeData={intakeData} />);

      let submitBtn = container.querySelector('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      wrapper.setState({
        description: 'blah blah',
        disabled: false
      });

      // We need to find element again, or it won't appear updated
      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });
  });
});
