import React from 'react';
import { render } from '@testing-library/react';
import VhaHelp from '../../../app/help/components/VhaHelp';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import helpReducers, { initialState } from '../../../app/help/helpApiSlice';

describe('VhaHelp', () => {

  const setup = (state = {}) => {
    const helpState = { ...initialState, ...state };
    const store = createStore(helpReducers, { help: { ...helpState } });

    return render(<Provider store={store}>
      <VhaHelp />
    </Provider>);
  };

  test('renders the help page', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });
});
