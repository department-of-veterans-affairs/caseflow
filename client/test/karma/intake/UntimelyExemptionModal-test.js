import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { reducer, generateInitialState } from '../../../app/intake';

import ReduxBase from '../../../app/components/ReduxBase';
import UntimelyExemptionModal from '../../../app/intake/components/UntimelyExemptionModal';
import { sample1 } from './testData';

describe('UntimelyExemptionModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const currentIssue = sample1.currentIssue1;

  // eslint-disable-next-line react/prop-types
  const wrappingComponent = ({ children }) => (
    <ReduxBase initialState={generateInitialState()} reducer={reducer} analyticsMiddlewareArgs={['intake']}>
      {children}
    </ReduxBase>
  );

  const defaultProps = {
    formType,
    intakeData,
    currentIssue,
    onSubmit: () => null,
    onCancel: () => null
  };

  context('renders', () => {
    it('renders button text', () => {
      const wrapper = mount(<UntimelyExemptionModal {...defaultProps} onSkip={() => null} />, { wrappingComponent });

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
      const wrapper = mount(<UntimelyExemptionModal {...defaultProps} />, { wrappingComponent });

      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(false);

      wrapper.setProps({ onSkip: () => null });
      expect(wrapper.find('.cf-modal-controls .no-matching-issues').exists()).to.equal(true);
    });

    // Disabling this for now until we switch to more robust JS testing framework
    // it('disables button when nothing selected', () => {
    //   const wrapper = mount(<UntimelyExemptionModal {...defaultProps} />, { wrappingComponent });

    //   const submitBtn = wrapper.find('.cf-modal-controls .add-issue');

    //   expect(submitBtn.prop('disabled')).to.be.eql(true);

    //   // This used to work for class component
    //   // wrapper.setState({
    //   //   untimelyExemption: true
    //   // });

    //   // This... also doesn't appear to be sufficient to trigger the React click handlers and state change
    //   wrapper.find('.cf-modal-body label[htmlFor="untimely-exemption_true"]').simulate('click');

    //   // We need to find element again, or it won't appear updated
    //   expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).to.be.eql(false);
    // });
  });
});
