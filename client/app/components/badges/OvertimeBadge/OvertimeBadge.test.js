import React from 'react';
import { axe } from 'jest-axe';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import { render, screen, waitFor } from '@testing-library/react';

import OvertimeBadge from './OvertimeBadge';
import rootReducer from 'app/queue/reducers';
import { setCanViewOvertimeStatus } from 'app/queue/uiReducer/uiActions';

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
    const { container } = setupOvertimeBadge(store, { overtime: true });

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

  it('does show if the appeal is marked as overtime and the user can view overtime badges', async () => {
    const store = getStore();

    store.dispatch(setCanViewOvertimeStatus(true));
    setupOvertimeBadge(store, { overtime: true });

    await waitFor(() => {
      expect(screen.getByText(tooltipText)).toBeInTheDocument();
    });
  });

  it('passes a11y', async () => {
    const store = getStore();

    store.dispatch(setCanViewOvertimeStatus(true));
    const { container } = setupOvertimeBadge(store, { overtime: true });

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
