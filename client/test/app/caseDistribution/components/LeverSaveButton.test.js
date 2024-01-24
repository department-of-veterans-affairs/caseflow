import React from 'react';
import { render, waitFor} from '@testing-library/react';
import LeverSaveButton from 'app/caseDistribution/components/LeverSaveButton';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Lever Save Button', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingBatchLevers = { batch: testingBatchLevers };
  // let lever = testingBatchLevers[0];

  it('Lever Save Button behavior for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );
    // should not render for members, maybe the store is being mocked incorrectly?
    expect(document.querySelector('#LeversSaveButton')).toBeNull()
  });

  it('renders Lever Save Button for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );
    expect(document.querySelector('#LeversSaveButton')).toHaveTextContent('Save');
  });
});
