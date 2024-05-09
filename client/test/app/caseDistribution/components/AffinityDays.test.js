import React from 'react';
import { render, waitFor} from '@testing-library/react';
import AffinityDays from 'app/caseDistribution/components/AffinityDays';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mockAffinityDaysLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Affinity Days Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingAffinityDaysLevers = { affinity: mockAffinityDaysLevers };
  let lever = mockAffinityDaysLevers[0];

  it('renders Affinity Days Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );
    const option = lever.options.find((opt) => opt.selected);
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
    const logSpy = jest.spyOn(console, 'log');

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );

    let radioOption = wrapper.find('input[id="ama_hearing_case_affinity_days-value"]');
    let radioOption2 = wrapper.find('input[id="ama_hearing_case_affinity_days-infinite"]');
    let radioOption3 = wrapper.find('input[id="ama_hearing_case_affinity_days-omit"]');

    // Sets radioOption input of value to "true"
    radioOption.getDOMNode().checked = true;
    radioOption2.getDOMNode().checked = false;
    radioOption3.getDOMNode().checked = false;

    // Ensure that all Radio Options are correctly set
    expect(radioOption.getDOMNode().checked).toEqual(true);
    expect(radioOption2.getDOMNode().checked).toEqual(false);
    expect(radioOption3.getDOMNode().checked).toEqual(false);

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

    waitFor(() => expect(logSpy).toHaveBeenCalledWith('not implemented'));
    waitFor(() => expect(inputField.prop('value').toBe(eventForValid.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').toBe('')));
  });

  it('should display the input text when radio option selected', () => {
    const inputData = { target: { value: 'test value' } };
    const logSpy = jest.spyOn(console, 'log');
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );

    let radioOption = wrapper.find('input[id="ama_hearing_case_aod_affinity_days-value"]');

    // Sets radioOption input of value to "true"
    radioOption.getDOMNode().checked = true;
    expect(radioOption.getDOMNode().checked).toEqual(true);

    let inputField = wrapper.find('input[id="ama_hearing_case_aod_affinity_days-0-input"]');

    // Calls simulate change to set value outside of min/max range
    waitFor(() => inputField.simulate('change', inputData));

    wrapper.update();

    waitFor(() => expect(logSpy).toHaveBeenCalledWith('not implemented'));
    waitFor(() => expect(inputField.prop('value').toBe(inputData.target.value)));
  });

  it('dynamically renders * in the lever label', () => {
    lever.algorithms_used = ["docket", "proportion"]

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <AffinityDays />
      </Provider>
    );

    expect(wrapper.text()).toContain(lever.title + '*');
  });
});
