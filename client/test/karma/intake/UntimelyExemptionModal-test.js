import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import UntimelyExemptionModal from '../../../app/intake/components/UntimelyExemptionModal';
import { sample1 } from './testData';

describe('UntimelyExemptionModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const currentIssue = sample1.currentIssue1;

  context('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(
        <UntimelyExemptionModal
          formType={formType}
          intakeData={intakeData}
          onSkip={() => null}
          currentIssue={currentIssue}
        />
      );

      const cancelBtn = wrapper.find('.cf-modal-controls .close-modal');
      const skipBtn = wrapper.find('.cf-modal-controls .no-matching-issues');
      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(cancelBtn.text()).to.be.eql('Cancel adding this issue');
      expect(skipBtn.text()).to.be.eql('None of these match, see more options');
      expect(submitBtn.text()).to.be.eql('Add this issue');

      wrapper.setProps({
        cancelText: 'cancel',
        skipText: 'skip',
        submitText: 'submit'
      });

      expect(cancelBtn.text()).to.be.eql('cancel');
      expect(skipBtn.text()).to.be.eql('skip');
      expect(submitBtn.text()).to.be.eql('submit');
    });

    it('skip button only with onSkip prop', () => {
      const wrapper = mount(
        <UntimelyExemptionModal formType={formType} intakeData={intakeData} currentIssue={currentIssue} />
      );

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(
        <UntimelyExemptionModal formType={formType} intakeData={intakeData} currentIssue={currentIssue} />
      );

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).to.be.eql(true);

      wrapper.setState({
        untimelyExemption: true
      });

      // We need to find element again, or it won't appear updated
      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).to.be.eql(false);
    });
  });
});
