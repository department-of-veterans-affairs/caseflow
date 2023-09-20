/* eslint-disable max-len */
import React from 'react';
import { mount } from 'enzyme';

import AddIssuesModal from '../../../app/intake/components/AddIssuesModal';
import { sample1 } from './testData';

describe('AddIssuesModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureToggles = {mst_identification: true}

  describe('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(<AddIssuesModal featureToggles={featureToggles} formType={formType} intakeData={intakeData} onSkip={() => null} />);

      const cancelBtn = wrapper.find('.cf-modal-controls .close-modal');
      const skipBtn = wrapper.find('.cf-modal-controls .no-matching-issues');
      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(cancelBtn.text()).toBe('Cancel adding this issue');
      expect(skipBtn.text()).toBe('None of these match, see more options');
      expect(submitBtn.text()).toBe('Next');

      wrapper.setProps({
        cancelText: 'cancel',
        skipText: 'skip',
        submitText: 'submit',
      });

      expect(cancelBtn.text()).toBe('cancel');
      expect(skipBtn.text()).toBe('skip');
      expect(submitBtn.text()).toBe('submit');
    });

    it('skip button only with onSkip prop', () => {
      const wrapper = mount(<AddIssuesModal featureToggles={featureToggles} formType={formType} intakeData={intakeData} />);

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(<AddIssuesModal featureToggles={featureToggles} formType={formType} intakeData={intakeData} />);

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      wrapper.setState({
        selectedContestableIssueIndex: '2'
      });

      // We need to find element again, or it won't appear updated
      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });
  });
});
