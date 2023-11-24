import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import { axe } from 'jest-axe';

import ReviewPage from 'app/nonComp/pages/ReviewPage';
import CombinedNonCompReducer from 'app/nonComp/reducers';

const basicVhaProps = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  decisionIssuesStatus: {},
  isBusinessLineAdmin: true,
  businessLineConfig: {
    tabs: ['incomplete', 'in_progress', 'completed'],
    canGenerateClaimHistory: true,
  }
};

const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const renderReviewPage = (storeValues = {}) => {
  // const nonCompReducer = createReducer({ nonComp: props });

  const store = createStore(
    CombinedNonCompReducer,
    storeValues,
    compose(applyMiddleware(thunk))
  );

  return render(
    <Provider store={store} >
      <ReviewPage />
    </Provider>
  );
};

describe('ReviewPage', () => {
  beforeEach(() => {
    renderReviewPage(basicVhaProps);
  });

  // it('passes a11y testing', async () => {
  //   const { container } = setup();

  //   const results = await axe(container);

  //   expect(results).toHaveNoViolations();
  // });

  // it('renders correctly', () => {
  //   const { container } = setup();

  //   expect(container).toMatchSnapshot();
  // });

  it('renders a button to intake a new form', () => {
    expect(screen.getByText('+ Intake new form')).toBeInTheDocument();
  });
});
