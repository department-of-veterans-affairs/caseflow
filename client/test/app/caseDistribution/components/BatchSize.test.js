import React from 'react';
import { render, waitFor} from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { levers, testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Batch Size Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let batchSizeLevers = levers.filter((lever) => (lever.lever_group === 'batch'));
  let batchSizeTestLever = batchSizeLevers[0];
  let leversWithBatchLevers = { batch: batchSizeLevers };

  it('renders the Batch Size Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeTestLever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeTestLever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(batchSizeTestLever.value);
  });

  it('renders disabled in ui Batch Size levers', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeTestLever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeTestLever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(batchSizeTestLever.value);
  });

  it('sets input to invalid for error and sets input to valid to remove error', () => {
    const eventForError = { target: { value: 2 } };
    const eventForValid = { target: { value: 10 } };

    const store = getStore();

    let leversWithTestingBatchLevers = {
      batch: testingBatchLevers,
    };

    let lever = testingBatchLevers[0];

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    let inputField = wrapper.find('input[name="test-lever"]');

    // Calls simulate change to set value outside of min/max range
    waitFor(() => inputField.simulate('change', eventForError));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(eventForError.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').
      toBe(`Please enter a value greater than or equal to ${ lever.min_value }`)));

    // Calls simulate change to set value within min/max range
    waitFor(() => inputField.simulate('change', eventForValid));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(eventForValid.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').toBe('')));
  });
});
