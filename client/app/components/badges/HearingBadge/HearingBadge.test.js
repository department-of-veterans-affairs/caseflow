import React from 'react';
import { axe } from 'jest-axe';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import { render, screen, waitFor } from '@testing-library/react';

import rootReducer from 'app/queue/reducers';
import HearingBadge from './HearingBadge';

describe('HearingBadge', () => {

  const defaultHearing = {
    heldBy: 'ExampleJudgeName',
    disposition: 'ExampleDispositionText',
    date: '2020-01-15',
    type: 'AMA',
    is_virtual: false
  };

  const tooltipText = 'H';

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const getHearingBadge = (store, hearing) => render(
    <Provider store={store}>
      <HearingBadge hearing={hearing} />
    </Provider>
  );

  it('renders correctly', () => {
    const store = getStore();
    const component = getHearingBadge(store, defaultHearing);

    expect(component).toMatchSnapshot();
  });


  it('displays "Virtual" when is_virtual is true', () => {
    const store = getStore();
    const hearingWithVirtual = { ...defaultHearing, is_virtual: true };

    getHearingBadge(store, hearingWithVirtual);
    expect(screen.getByText('Virtual')).toBeInTheDocument();
  });

  it('displays if there are hearings', async () => {
    const store = getStore();

    getHearingBadge(store, defaultHearing);

    await waitFor(() => {
      expect(screen.getByText(tooltipText)).toBeInTheDocument();
    });
  });

  it('doesn\'t show if there are no hearings', () => {
    const store = getStore();
    const component = getHearingBadge(store, undefined); // eslint-disable-line no-undefined

    expect(component.queryByRole('tooltip')).toBeNull;
  });

  it('passes a11y', async () => {
    const store = getStore();
    const { container } = getHearingBadge(store, defaultHearing);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
