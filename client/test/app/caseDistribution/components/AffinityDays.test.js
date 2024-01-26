import React from 'react';
import { render, waitFor} from '@testing-library/react';
import AffinityDays from 'app/caseDistribution/components/AffinityDays';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { testingAffinityDaysLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Affinity Days Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingAffinityDaysLevers = { affinity: testingAffinityDaysLevers };
  let lever = testingAffinityDaysLevers[0];

  it('renders Affinity Days Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );
    const option = lever.options.find((opt) => opt.item === 'option_1');
    const value = `${option.text} ${option.value} ${option.unit}`;

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(value);
  });

  it('renders Affinity Days Levers for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.unit);
  });

  it('sets input to invalid for error and sets input to valid to remove error', () => {
    const eventForError = { target: { value: 150 } };
    const eventForValid = { target: { value: 10 } };

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );

    let radioOption = wrapper.find('input[id="ama_hearing_case_affinity_days-option_1"]');
    let radioOption1 = wrapper.find('input[id="ama_hearing_case_affinity_days-infinite"]');

    expect(radioOption.getDOMNode().checked).toEqual(true);
    expect(radioOption1.getDOMNode().checked).toEqual(false);

    let inputField = wrapper.find('input[id="ama_hearing_case_affinity_days-0-input"]');

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
