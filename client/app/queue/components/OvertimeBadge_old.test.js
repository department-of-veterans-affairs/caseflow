import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../reducers';
import thunk from 'redux-thunk';
import OvertimeBadge from 'app/queue/components/OvertimeBadge';
import { Provider } from 'react-redux';
import { render, screen } from '@testing-library/react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { axe } from 'jest-axe';
import { setCanViewOvertimeStatus } from 'app/queue/uiReducer/uiActions';
import '@testing-library/jest-dom'


describe('OvertimeBadge', () => {
    const defaultAppeal = {
      canViewOvertimeStatus: true,
      overtime: true
    };
    
    const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
      
    const getOvertimeBadge = (store) => {
      return mount(
        <Provider store={store}>
          <OvertimeBadge appeal={defaultAppeal} />
        </Provider>
      );
    };

    it('renders correctly', () => {
      const store = getStore();
      store.dispatch(setCanViewOvertimeStatus(true));
      const component = getOvertimeBadge(store);

      expect(component).toMatchSnapshot();
    });

    it('does not show if the appeal is not marked as overtime', () => {
      const store = getStore();
      store.dispatch(setCanViewOvertimeStatus(true));
      const component = getOvertimeBadge(store, { overtime: false });
    
      expect(component.queryAllByRole('div', {class: 'cf-overtime-badge'})).to.have.length(0);
    });

    it('does not show if the user cannot view overtime badges', () => {
      const store = getStore();
      store.dispatch(setCanViewOvertimeStatus(false));
      const screen = getOvertimeBadge(store, { overtime: true });

      //expect(component.find('div')).to.have.length(0);
      expect(screen.queryAllByRole('div', {class: 'cf-overtime-badge'})).to.have.length(0);
    });

    it('does show if the appeal is marked as overtime and the user can view overtime badges', () => {
      const store = getStore();
      store.dispatch(setCanViewOvertimeStatus(true));
      const component = getOvertimeBadge(store, { overtime: true });

      expect(component.queryAllByRole('div', {class: 'cf-overtime-badge'})).to.have.length(1);
    });

      // it('passes a11y testing', async () => {
      //   const store = getStore();
      //   store.dispatch(setCanViewOvertimeStatus(true));

      //   const component = getOvertimeBadge(store, { overtime: true });
      //   const { container } = render(<OvertimeBadge {...component} />);
    
      //   const results = await axe(container);
    
      //   expect(results).toHaveNoViolations();
      // });
});

