import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  context('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
        formType={formType}
        intakeData={intakeData}
        onSkip={() => null} />
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
       <NonratingRequestIssueModal
       formType={formType}
       intakeData={intakeData}
       />);

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(
        <NonratingRequestIssueModal
        formType={formType}
        intakeData={intakeData} />
        );

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).to.be.eql(true);

      //   Lots of things required for button to be enabled...
      wrapper.setState({
        benefitType: 'compensation',
        category: { label: 'Apportionment',
          value: 'Apportionment' },
        decisionDate: '06/01/2019',
        dateError: false,
        description: 'thing'
      });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).to.be.eql(false);
    });
  });
});
