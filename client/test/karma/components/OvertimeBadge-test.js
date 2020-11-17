import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { expect } from 'chai';
import { mount } from 'enzyme';

import OvertimeBadge from '../../../app/queue/components/OvertimeBadge';
import { setCanViewOvertimeStatus } from '../../../app/queue/uiReducer/uiActions';


describe('OvertimeBadge', () => {
  context('base', () => {
    const getOvertimeBadge = (store, appeal) => {
      return mount(
        <Provider store={store}>
          <OvertimeBadge appeal={appeal} />
        </Provider>
      );
    };
    const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

    it('doesn\'t show if the appeal is not marked as overtime', () => {
      const store = getStore();
      const wrapper = getOvertimeBadge(store, { overtime: false });

      expect(wrapper.find('div')).to.have.length(0);
      expect(wrapper.find('.cf-overtime-badge')).to.have.length(0);
    });

    it('doesn\'t show if the user cannot view overtime badges', () => {
      const store = getStore();
      const wrapper = getOvertimeBadge(store, { overtime: true });

      expect(wrapper.find('div')).to.have.length(0);
      expect(wrapper.find('.cf-overtime-badge')).to.have.length(0);
    });

    it('does show if the appeal is marked as overtime and the user can view overtime badges', () => {
      const store = getStore();
      store.dispatch(setCanViewOvertimeStatus(true));

      const wrapper = getOvertimeBadge(store, { overtime: true });

      expect(wrapper.find('.cf-overtime-badge')).to.have.length(1);
    });
  });
});
