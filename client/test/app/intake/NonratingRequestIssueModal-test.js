import React from 'react';
import { mount } from 'enzyme';

import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import PreDocketRadioField from '../../../app/intake/components/PreDocketRadioField';
import { sample1 } from './testData';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureToggles = { vhaPreDocketAppeals: false };

  describe('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType={formType}
          intakeData={intakeData}
          featureToggles={featureToggles}
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
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType={formType}
          intakeData={intakeData}
          featureToggles={featureToggles}
        />);

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).toBe(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType={formType}
          intakeData={intakeData}
          featureToggles={featureToggles} />
      );

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      //   Lots of things required for button to be enabled...
      wrapper.setState({
        benefitType: 'compensation',
        category: { label: 'Apportionment',
          value: 'Apportionment' },
        decisionDate: '06/01/2019',
        dateError: false,
        description: 'thing'
      });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });
  });

  describe('on appeal, with EMO Pre-Docket', () => {
    const featureTogglesEMOPreDocket = { vhaPreDocketAppeals: false, educationPreDocketAppeals: true };

    it(' enabled selecting benefit type of "education" renders PreDocketRadioField', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType="appeal"
          intakeData={intakeData}
          featureToggles={featureTogglesEMOPreDocket} />
      );

      // Benefit type isn't education, so it should not be rendered
      expect(wrapper.find('.cf-is-predocket-needed')).toHaveLength(0);

      wrapper.setState({
        benefitType: 'education'
      });

      // Benefit type is now education, so it should be rendered
      expect(wrapper.find('.cf-is-predocket-needed')).toHaveLength(1);
    });
  });
});
