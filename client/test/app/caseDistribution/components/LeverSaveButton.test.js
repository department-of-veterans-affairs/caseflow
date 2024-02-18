import React from 'react';
import { render, screen } from '@testing-library/react';
import LeverSaveButton from '../../../../app/caseDistribution/components/LeverSaveButton';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import * as leversSelectors from 'app/caseDistribution/reducers/levers/leversSelector';
import thunk from 'redux-thunk';
import { setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';

describe('Lever Save Button', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Save Button for Admin Users', () => {
    const store = getStore();

    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );
    expect(screen.getByText('Save')).toBeInTheDocument();
  });

  it('will be disabled initially', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );

    expect(screen.getByText('Save')).toBeDisabled();
  });

  it('activates Save Button when conditions are met', () => {
    const store = getStore();

    const changedLeversData = [
      { title: 'Alternate Batch Size*',
        backendValue: '50',
        value: '15',
        data_type: 'number' },
    ];

    jest.spyOn(leversSelectors, 'hasChangedLevers').mockReturnValue(changedLeversData);

    render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );

    expect(screen.getByText('Save')).not.toBeDisabled();
  });
});
