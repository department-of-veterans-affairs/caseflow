import React from 'react';
import { mount } from 'enzyme';

import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureTogglesEMOPreDocket = { eduPreDocketAppeals: true };

  const wrapper = mount(
    <NonratingRequestIssueModal
      formType={formType}
      intakeData={intakeData}
      onSkip={() => null}
      featureToggles={{}}
    />
  );

  const wrapperNoSkip = mount(
    <NonratingRequestIssueModal
      formType={formType}
      intakeData={intakeData}
      featureToggles={{}}
    />
  );

  const wrapperEMOPreDocket = mount(
    <NonratingRequestIssueModal
      formType="appeal"
      intakeData={intakeData}
      featureToggles={featureTogglesEMOPreDocket}
    />
  );

  describe('renders', () => {
    const cancelBtn = wrapper.find('.cf-modal-controls .close-modal');
    const skipBtn = wrapper.find('.cf-modal-controls .no-matching-issues');
    const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

    it('renders button text', () => {
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
      expect(wrapperNoSkip.find('.cf-modal-controls .no-matching-issues').exists()).toBe(false);

      wrapperNoSkip.setProps({ onSkip: () => null });

      expect(wrapperNoSkip.find('.cf-modal-controls .no-matching-issues').exists()).toBe(true);
    });

    it('disables button when nothing selected', () => {
      expect(submitBtn.prop('disabled')).toBe(true);

      //   Lots of things required for button to be enabled...
      wrapper.setState({
        benefitType: 'compensation',
        category: {
          label: 'Apportionment',
          value: 'Apportionment'
        },
        decisionDate: '06/01/2019',
        dateError: false,
        description: 'thing'
      });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });
  });

  describe('on appeal, with EMO Pre-Docket', () => {
    const benefitType = wrapperEMOPreDocket.find('.cf-is-predocket-needed');

    it(' enabled selecting benefit type of "education" renders PreDocketRadioField', () => {
      // Benefit type isn't education, so it should not be rendered
      expect(benefitType).toHaveLength(0);

      wrapperEMOPreDocket.setState({
        benefitType: 'education'
      });

      // Benefit type is now education, so it should be rendered
      expect(wrapperEMOPreDocket.find('.cf-is-predocket-needed')).toHaveLength(1);
    });

    it('submit button is disabled with Education benefit_type if pre-docket selection is empty', () => {
      // Switch to an Education issue, but don't fill in pre-docket field
      wrapperEMOPreDocket.setState({
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

      const submitBtn = wrapperEMOPreDocket.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      // Fill in pre-docket field to make sure the submit button gets enabled
      // Note that the radio field values are strings.
      wrapperEMOPreDocket.setState({
        isPreDocketNeeded: 'false'
      });

      expect(wrapperEMOPreDocket.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });

    it('Decision date does not have an optional label ', () => {
      wrapperEMOPreDocket.setState({
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

      // Since this is a non vha benifit type the decision date is required, so the optional label should not be visible
      const optionalLabel = wrapperEMOPreDocket.find('.cf-optional');
      const submitButton = wrapperEMOPreDocket.find('.cf-modal-controls .add-issue');

      expect(optionalLabel).not.toBe();
      expect(submitButton.prop('disabled')).toBe(true);
    });
  });

  describe('on higher level review, with VHA benefit type', () => {
    wrapperNoSkip.setState({
      benefitType: 'vha',
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'test'
    });

    const optionalLabel = wrapperNoSkip.find('.cf-optional');
    const submitButton = wrapperNoSkip.find('.cf-modal-controls .add-issue');

    it('renders modal with decision date field being optional', () => {
      expect(optionalLabel.text()).toBe('Optional');
    });

    it('submit button is enabled without a decision date entered', () => {
      expect(submitButton.prop('disabled')).toBe(false);
    });
  });
});
