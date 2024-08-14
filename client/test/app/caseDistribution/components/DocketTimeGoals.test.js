import React from 'react';
import { render, waitFor, screen, fireEvent } from '@testing-library/react';
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

  it('renders Docket Time Goals Levers for Admin Users', async () => {
    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    const {container} = render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>);

    const leverTimeGoal = container.querySelector('input[name="ama_hearing_docket_time_goals"]');
    const leverDistPrior = container.querySelector('input[name="toggle-ama_hearing_start_distribution_prior_to_goals"]');

    // Use waitFor for asynchronous expectations if necessary
    await waitFor(() => {
      expect(leverTimeGoal).toHaveValue(testTimeGoalLever.value.toString());
      expect(leverDistPrior).toHaveValue(testDistPriorLever.value.toString());
    });

    expect(container.querySelector('div[aria-label="AMA Hearings Docket Time Goals"]')).toBeInTheDocument();
  });

  it('sets input of Time Goal Lever to invalid for error and sets input to valid to remove error', async () => {
    const eventForError = { target: { value: 1234 } };
    const eventForValid = { target: { value: 30 } };

    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    const { container } = render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>
    );

    const leverTimeGoal = container.querySelector('input[name="ama_hearing_docket_time_goals"]');

    // Calls simulate change to set value outside of min/max range
    await waitFor(() => fireEvent.change(leverTimeGoal, eventForError));

    expect(screen.getByDisplayValue(eventForError.target.value.toString())).toBeInTheDocument();
    expect(screen.getByText('Please enter a value from 0 to 888')).toBeInTheDocument();

    // Calls simulate change to set value within min/max range
    await waitFor(() => fireEvent.change(leverTimeGoal, eventForValid));

    expect(screen.getByDisplayValue(eventForValid.target.value.toString())).toBeInTheDocument();
    expect(screen.queryByText('Please enter a value from 0 to 888')).not.toBeInTheDocument();
  });

  it('dynamically renders * in the lever label', () => {
    testDistPriorLever.algorithms_used = ['docket', 'proportion'];
    testTimeGoalLever.algorithms_used = ['docket', 'proportion'];
    let testTitle = sectionTitles[testDistPriorLever.item];

    const store = getStore();

    store.dispatch(loadLevers(levers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <DocketTimeGoals />
      </Provider>);

      expect(screen.getByText(`${testTitle }*`)).toBeInTheDocument();
  });
});
