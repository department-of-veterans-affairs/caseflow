import React from 'react';
import { mount } from 'enzyme';

import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  describe('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType={formType}
          intakeData={intakeData}
          onSkip={() => null}
          featureToggles={{}}
        />
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
          featureToggles={{}}
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
          featureToggles={{}} />
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
    const featureTogglesEMOPreDocket = { eduPreDocketAppeals: true };

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

    it('submit button is disabled with Education benefit_type if pre-docket selection is empty', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType="appeal"
          intakeData={intakeData}
          featureToggles={featureTogglesEMOPreDocket} />
      );

      // Switch to an Education issue, but don't fill in pre-docket field
      wrapper.setState({
        benefitType: 'education',
        category: {
          label: 'accrued',
          value: 'accrued'
        },
        decisionDate: '03/30/2022',
        dateError: false,
        description: 'thing',
        isPreDocketNeeded: null
      });

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      // Fill in pre-docket field to make sure the submit button gets enabled
      // Note that the radio field values are strings.
      wrapper.setState({
        isPreDocketNeeded: 'false'
      });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });

    it('Decision date does not have an optional label ', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
          formType="appeal"
          intakeData={intakeData}
          featureToggles={{}} />
      );

      // Since this is a non vha benifit type the decision date is required, so the optional label should not be visible
      const optionalLabel = wrapper.find('.cf-optional');
      const submitButton = wrapper.find('.cf-modal-controls .add-issue');

      expect(optionalLabel).not.toBe();
      expect(submitButton.prop('disabled')).toBe(true);
    });
  });

  describe('on higher level review, with VHA benefit type', () => {
    const wrapper = mount(
      <NonratingRequestIssueModal
        formType={formType}
        intakeData={intakeData}
        featureToggles={{}} />
    );

    wrapper.setState({
      benefitType: 'vha',
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'test'
    });

    const optionalLabel = wrapper.find('.cf-optional');
    const submitButton = wrapper.find('.cf-modal-controls .add-issue');

    it('renders modal with decision date field being optional', () => {
      expect(optionalLabel.text()).toBe('Optional');
    });

    it('submit button is enabled without a decision date entered', () => {
      expect(submitButton.prop('disabled')).toBe(false);
    });
  });
});
