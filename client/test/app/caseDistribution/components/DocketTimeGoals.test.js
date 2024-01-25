import React from 'react';
import { render, waitFor} from '@testing-library/react';
import DocketTimeGoals from 'app/caseDistribution/components/DocketTimeGoals';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import {
  testingDocketDistributionPriorLevers,
  testingDocketTimeGoalsLevers
} from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Docket Time Goals Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  // "static": "static",
  // "batch": "batch",
  // "affinity": "affinity",
  // "docket_distribution_prior": "docket_distribution_prior",
  // "docket_time_goal": "docket_time_goal"

  let levers = {
    docket_distribution_prior: testingDocketDistributionPriorLevers,

    docket_time_goal: testingDocketTimeGoalsLevers
  };
  let testTimeGoalLever = testingDocketTimeGoalsLevers[0];
  let testDistPriorLever = testingDocketDistributionPriorLevers[0];

  it.skip('renders Batch Size Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );
    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    // expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.value);
  });

  it.skip('renders Batch Size Levers for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );

    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    // expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.value);
  });


  it.skip('sets input of Time Goal Lever to invalid for error and sets input to valid to remove error', () => {
    const eventForError = { target: { value: 1234 } };
    const eventForValid = { target: { value: 30 } };

    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );

    let inputField = wrapper.find('input[name="ama_hearings_docket_time_goals"]');

    // Calls simulate change to set value outside of min/max range
    waitFor(() => inputField.simulate('change', eventForError));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(eventForError.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').
      toBe(`Please enter a value greater than or equal to ${ testTimeGoalLever.min_value }`)));

    // Calls simulate change to set value within min/max range
    waitFor(() => inputField.simulate('change', eventForValid));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(eventForValid.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').toBe('')));
  });

  it.skip('enabled and disables the toggle lever button', () => {
    const eventForError = { target: { value: 1234 } };
    const eventForValid = { target: { value: 30 } };

    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    let wrapper = mount(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );

    const wrapper = mount(      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>);
    const instance = wrapper.instance();

    const instance = wrapper.instance();
    // Toggle Lever
    instance.toggleLever(0);
    wrapper.update();

    // waitFor(() => expect(inputField.prop('value').toBe(eventForError.target.value)));

    // wrapper.instance().toggleLever(0);
    // wrapper.update();

    // waitFor(() => expect(inputField.prop('value').toBe(eventForValid.target.value)));

  });


});
