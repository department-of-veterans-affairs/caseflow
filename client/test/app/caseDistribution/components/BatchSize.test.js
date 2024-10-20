import React from 'react';
import { render, waitFor, screen, fireEvent} from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mockBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin} from 'app/caseDistribution/reducers/levers/leversActions';

describe('Batch Size Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingBatchLevers = { batch: mockBatchLevers };
  let lever = mockBatchLevers[0];

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
    expect(document.querySelector('.lever-right').getAttribute('aria-label')).
      toBe(null);
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

  it('renders aria text Levers for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

      expect(screen.getByRole('textbox', { name: /Test Title Lever\*/i })).toBeInTheDocument();
  });

  it('sets input to invalid for error and sets input to valid to remove error', () => {
    const eventForError = { target: { value: 2 } };
    const eventForValid = { target: { value: 10 } };

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    let inputField = screen.getByRole('textbox', { name: /Test Title Lever\*/i });

    // Calls simulate change to set value outside of min/max range
    fireEvent.change(inputField, eventForError);

    waitFor(() => expect(inputField.value).toBe(eventForError.target.value));
    waitFor(() =>expect(screen.getByText(new RegExp(`Please enter a value greater than or equal to ${lever.min_value}`))).
    toBeInTheDocument());

    // // Calls simulate change to set value within min/max range
    fireEvent.change(inputField, eventForValid);

    waitFor(() => expect(inputField.value).toBe(eventForValid.target.value));
    waitFor(() =>expect(screen.getByText(new RegExp(`Please enter a value greater than or equal to ${lever.min_value}`))).
    not.toBeInTheDocument());
  });

  it('dynamically renders * in the lever label', () => {
    lever.algorithms_used = ["docket", "proportion"]

    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(screen.getByText(lever.title + '*')).toBeInTheDocument();
  });
});
