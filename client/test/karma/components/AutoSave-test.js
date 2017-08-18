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

const appColors = {
  certification: AppConstants.LOADING_INDICATOR_COLOR_CERTIFICATION,
  dispatch: AppConstants.LOADING_INDICATOR_COLOR_DISPATCH,
  efolder: AppConstants.LOADING_INDICATOR_COLOR_EFOLDER,
  feedback: AppConstants.LOADING_INDICATOR_COLOR_FEEDBACK,
  hearings: AppConstants.LOADING_INDICATOR_COLOR_HEARING_PREP,
  reader: AppConstants.LOADING_INDICATOR_COLOR_READER
};

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

    it('renders a spinner for each application', () => {
      let wrapper;

      Object.keys(appColors).forEach((key) => {
        wrapper = mount(
          <Provider store={store}>
            <AutoSave
              app={key}
              isSaving
              beforeWindowClosesActionCreator={actionCreator}
            />
          </Provider>
        );

        expect(wrapper.find(`[fill="${appColors[key]}"]`).first()).to.have.length(1);
      });
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
