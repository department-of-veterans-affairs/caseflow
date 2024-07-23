import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

let initialState = {
  correspondence: correspondenceData
};
const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

describe('CorrespondenceDetails', () => {
  const props = {
    correspondence: {
      veteranFullName: 'John Doe',
      veteranFileNumber: '123456789',
      mailTasks: ['Task 1', 'Task 2']
    }
  };

  beforeEach(() => {
    store.dispatch = jest.fn();
  });

  it('renders the component', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Veteran ID:')).toBeInTheDocument();
    expect(screen.getByText('Correspondence and Appeal Tasks')).toBeInTheDocument();
    expect(screen.getByText('Package Details')).toBeInTheDocument();
    expect(screen.getByText('Response Letters')).toBeInTheDocument();
    expect(screen.getByText('Associated Prior Mail')).toBeInTheDocument();
  });

  it('displays the correspondence tasks correctly', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );

    expect(screen.getByText('Completed Mail Tasks')).toBeInTheDocument();
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();
  });
});
