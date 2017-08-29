import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { asyncTest, pause } from '../../helpers/AsyncTests';
import { AutoSave } from '../../../app/components/AutoSave';
import * as AppConstants from '../../../app/constants/AppConstants';

export const actionCreator = () => ({ my: 'action' });

describe('AutoSave', () => {
  context('when isSaving is not true', () => {
    it('renders "Last saved at"', () => {
      const wrapper = mount(
          <AutoSave beforeWindowClosesActionCreator={actionCreator} />
      );

      expect(wrapper.find('.saving').text()).to.include('Last saved at');
    });
  });

  context('when isSaving is true', () => {
    it('renders default spinner', () => {
      const wrapper = mount(
          <AutoSave
            isSaving
            beforeWindowClosesActionCreator={actionCreator}
          />
      );

      const spinner = wrapper.find(`[fill="${AppConstants.LOADING_INDICATOR_COLOR_DEFAULT}"]`).first();

      expect(spinner).to.have.length(1);
    });

    it('renders a spinner for an application', () => {
      const wrapper = mount(
        <AutoSave
          isSaving
          spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
          beforeWindowClosesActionCreator={actionCreator}
        />
      );

      const spinner = wrapper.find(`[fill="${AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}"]`).first();

      expect(spinner).to.have.length(1);
    });
  });

  xit('calls an action creator before window closes', asyncTest(async () => {
    mount(
      <AutoSave beforeWindowClosesActionCreator={actionCreator} />
    );
    window.close();
    await pause();

    expect(actionCreator.calledOnce).to.equal(true);
  }));
});
