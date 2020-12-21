import React from 'react';
import {
  render
} from '@testing-library/react';
import { Provider } from 'react-redux';
import configureStore from 'redux-mock-store';


import { SelectClaimant } from 'app/intake/components/SelectClaimant';


describe('SelectClaimant', () => {
  const mockStore = configureStore();

  it('renders correctly', () => {
    let store = mockStore({
      featureToggles: {}
    });

    const container = render(<Provider store={store}>
      <SelectClaimant
        relationships={[]}
      />
    </Provider>);

    expect(container).toMatchSnapshot();
  });
});
