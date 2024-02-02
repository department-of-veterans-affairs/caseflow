import React from 'react';
import { render, waitFor} from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Batch Size Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingBatchLevers = { batch: testingBatchLevers };
  let lever = testingBatchLevers[0];

  it('renders Batch Size Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.value);
  });

  it('renders Batch Size Levers for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.unit);
  });

  it('sets input to invalid for error and sets input to valid to remove error', () => {
    const eventForError = { target: { value: 2 } };
    const eventForValid = { target: { value: 10 } };

    const store = getStore();

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

  it('dynamically renders * in the lever label', () => {
    lever.algorithms_used = ["docket", "proportion"]

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(wrapper.text()).toContain(lever.title + '*');
  });
});
