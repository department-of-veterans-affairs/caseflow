import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import AutoSave from '../../../app/components/AutoSave';
import * as AppConstants from '../../../app/constants/AppConstants';

export const actionCreator = () => ({ my: 'action' });

const fakeStore = (state) => ({
  default: () => {
    // do nothing
  },
  subscribe: () => {
    // do nothing
  },
  dispatch: () => {
    // do nothing
  },
  getState: () => ({ ...state })
});

const store = fakeStore({ dockets: {} });

describe('AutoSave', () => {
  context('when isSaving is not true', () => {
    it('renders "Last saved at"', () => {
      const wrapper = mount(
        <Provider store={store}>
          <AutoSave beforeWindowClosesActionCreator={actionCreator} />
        </Provider>
      );

      expect(wrapper.find('.saving').text()).to.include('Last saved at');
    });
  });

  context('when isSaving is true', () => {
    it('renders default spinner', () => {
      const wrapper = mount(
        <Provider store={store}>
          <AutoSave
            isSaving
            beforeWindowClosesActionCreator={actionCreator}
          />
        </Provider>
      );

      const spinner = wrapper.find(`[fill="${AppConstants.LOADING_INDICATOR_COLOR_DEFAULT}"]`).first();

      expect(spinner).to.have.length(1);
    });

    it('renders a spinner for an application', () => {
      const wrapper = mount(
        <Provider store={store}>
          <AutoSave
            isSaving
            spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARING_PREP}
            beforeWindowClosesActionCreator={actionCreator}
          />
        </Provider>
      );

      const spinner = wrapper.find(`[fill="${AppConstants.LOADING_INDICATOR_COLOR_HEARING_PREP}"]`).first();

      expect(spinner).to.have.length(1);
    });
  });

  it('calls an action creator before window closes', () => {
    mount(
      <Provider store={store}>
        <AutoSave beforeWindowClosesActionCreator={actionCreator} />
      </Provider>
    );

    /* eslint-disable no-unused-expressions */
    window.close();
    setTimeout(() => {
      expect(actionCreator.calledOnce).to.be.true;
    });
    /* eslint-enable no-unused-expressions */
  });
});
