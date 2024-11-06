import React from 'react';
import { mount } from 'enzyme';

import UnidentifiedIssuesModal from '../../../app/intake/components/UnidentifiedIssuesModal';
import { sample1 } from './testData';

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

      const cancelBtn = wrapper.find('.cf-modal-controls .close-modal');
      const skipBtn = wrapper.find('.cf-modal-controls .no-matching-issues');
      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(cancelBtn.text()).toBe('Cancel adding this issue');
      expect(skipBtn.text()).toBe('None of these match, see more options');
      expect(submitBtn.text()).toBe('Add this issue');

      wrapper.setProps({
        cancelText: 'cancel',
        skipText: 'skip',
        submitText: 'submit'
      });

      expect(cancelBtn.text()).toBe('cancel');
      expect(skipBtn.text()).toBe('skip');
      expect(submitBtn.text()).toBe('submit');
    });

    it('skip button only with onSkip prop', () => {
      const wrapper = mount(<UnidentifiedIssuesModal
        formType={formType}
        intakeData={intakeData} />);

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(<UnidentifiedIssuesModal formType={formType}
        intakeData={intakeData} />);

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);
    });

    it('enables when valid description entered', () => {
      const wrapper = mount(<UnidentifiedIssuesModal formType={formType}
        intakeData={intakeData} />);

      // Simulate user input of valid characters
      const descInput = wrapper.find('input[id="Transcribe the issue as it\'s written on the form"]');

      descInput.simulate('change', { target: { value: '1234567890-=`~!@#$%^&*()_+[]{}\\|;:' } });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(null);
    });

    it('disables when invalid description entered', () => {
      const wrapper = mount(<UnidentifiedIssuesModal formType={formType}
        intakeData={intakeData} />);

      // Simulate user input of invalid characters
      const descInput = wrapper.find('input[id="Transcribe the issue as it\'s written on the form"]');

      descInput.simulate('change', { target: { value: 'Not safe: \u{00A7} \u{2600} \u{2603} \u{260E} \u{2615}' } });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(true);
    });
  });
});
