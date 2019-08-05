import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import CorrectionTypeModal from '../../../app/intake/components/CorrectionTypeModal';
import { sample1 } from './testData';

describe('CorrectionTypeModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;

  context('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(<CorrectionTypeModal formType={formType} intakeData={intakeData} onSkip={() => null} />);

      const cancelBtn = wrapper.find('.cf-modal-controls .close-modal');
      const skipBtn = wrapper.find('.cf-modal-controls .no-matching-issues');
      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(cancelBtn.text()).to.be.eql('Cancel');
      expect(skipBtn.text()).to.be.eql('None of these match, see more options');
      expect(submitBtn.text()).to.be.eql('Next');

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
      const wrapper = mount(<CorrectionTypeModal formType={formType} intakeData={intakeData} />);

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(true);
    });

    it('disables button when nothing selected', () => {
      const wrapper = mount(<CorrectionTypeModal formType={formType} intakeData={intakeData} />);

      const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).to.be.eql(true);

      wrapper.setState({
        correctionType: 'control'
      });

      // We need to find element again, or it won't appear updated
      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).to.be.eql(false);
    });
  });
});
