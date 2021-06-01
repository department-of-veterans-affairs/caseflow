import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../reducers';
import thunk from 'redux-thunk';
import OvertimeBadge from 'app/queue/components/OvertimeBadge';
import { Provider } from 'react-redux';
import { setCanViewOvertimeStatus } from 'app/queue/uiReducer/uiActions';
import { axe } from 'jest-axe';
import { render } from '@testing-library/react';

describe('OvertimeBadge', () => {

  const tooltipText = 'OT';

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupOvertimeBadge = (store, appeal) => render(
      <Provider store={store}>
        <OvertimeBadge appeal={appeal} />
      </Provider>
  ); 

  it('renders correctly', () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(true));
    const {container} = setupOvertimeBadge(store, { overtime: true });

    expect(container).toMatchSnapshot();
  });

  it('doesn\'t show if the appeal is not marked as overtime', () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(true));
    const component = setupOvertimeBadge(store, { overtime: false });

    expect(component.queryByRole('tooltip')).toBeNull;
  });

  it('doesn\'t show if the user cannot view overtime badges', () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(false));
    const component = setupOvertimeBadge(store, { overtime: true });

    expect(component.queryByRole('tooltip')).toBeNull;
  });

  it('does show if the appeal is marked as overtime and the user can view overtime badges', () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(true));
    const component = setupOvertimeBadge(store, { overtime: true });

    expect(component.queryByRole('tooltip')).toHaveTextContent(tooltipText);
  });

  it('passes a11y', async () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(true));
    const { container } = setupOvertimeBadge(store, { overtime: true });

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
