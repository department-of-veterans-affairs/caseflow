import React from 'react';
import { render, waitFor } from '@testing-library/react';
import DocketTimeGoals from 'app/caseDistribution/components/DocketTimeGoals';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import {
  mockDocketDistributionPriorLevers,
  mockDocketTimeGoalsLevers
} from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';
import { sectionTitles } from '../../../../app/caseDistribution/constants';

describe('Docket Time Goals Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let levers = {
    docket_distribution_prior: mockDocketDistributionPriorLevers,
    docket_time_goal: mockDocketTimeGoalsLevers
  };
  let testTimeGoalLever = mockDocketTimeGoalsLevers[0];
  let testDistPriorLever = mockDocketDistributionPriorLevers[0];

  it('renders Docket Time Goals Levers for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-middle')).toHaveTextContent(testTimeGoalLever.value);
    expect(document.querySelector('.active-lever > .lever-middle')).toHaveTextContent(testTimeGoalLever.unit);
    expect(document.querySelector('.active-lever > .lever-right')).
      toHaveTextContent(testTimeGoalLever.is_toggle_active ? 'On' : 'Off');
  });

  it('renders Docket Time Goals Levers for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    const wrapper = mount(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>);

    let leverTimeGoal = wrapper.find('input[name="ama_hearing_docket_time_goals"]');
    let leverDistPrior = wrapper.find('input[name="ama_hearing_start_distribution_prior_to_goals"]');

    waitFor(() => expect(leverTimeGoal).toHaveTextContent(testTimeGoalLever.value));
    waitFor(() => expect(leverDistPrior).toHaveTextContent(testDistPriorLever.value));

    expect(wrapper.find('NumberField').first().
      prop('ariaLabelText')).toBe('AMA Hearings Docket Time Goals');
  });

  it('sets input of Time Goal Lever to invalid for error and sets input to valid to remove error', () => {
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
      toBe('Please enter a value from 0 to 999')));

    // Calls simulate change to set value within min/max range
    waitFor(() => inputField.simulate('change', eventForValid));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(eventForValid.target.value)));
    waitFor(() => expect(inputField.prop('errorMessage').toBe('')));
  });

  it('dynamically renders * in the lever label', () => {
    testDistPriorLever.algorithms_used = ['docket', 'proportion'];
    testTimeGoalLever.algorithms_used = ['docket', 'proportion'];
    let testTitle = sectionTitles[testDistPriorLever.item];

    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    const wrapper = mount(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>);

    expect(wrapper.text()).toContain(`${testTitle }*`);
  });
});
