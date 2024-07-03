import React from 'react';
import { render, screen } from '@testing-library/react';
import CaseDistributionContent from 'app/caseDistribution/components/CaseDistributionContent';
import { formattedLevers } from 'test/data/formattedCaseDistributionData';
import { createStore, applyMiddleware } from 'redux';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { loadAcdExcludeFromAffinity } from 'app/caseDistribution/reducers/levers/leversActions';
import rootReducer from 'app/caseDistribution/reducers/root';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import thunk from 'redux-thunk';

describe('CaseDistributionContent', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  const store = getStore();

  const setup = (testProps) =>
    render(
      <BrowserRouter>
        <Provider store={store}>
          <CaseDistributionContent {...testProps} />
        </Provider>
      </BrowserRouter>
    );

  it('renders the "CaseDistributionContent Component" with the data imported', () => {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(formattedLevers)),
      backendLevers: JSON.parse(JSON.stringify(formattedLevers))
    };
    const leverStore = createStore(leversReducer, preloadedState);

    let testLevers = {
      static: [],
      batch: [],
      affinity: [],
      docket_distribution_prior: [],
      docket_time_goal: []
    };

    let testProps = {
      levers: testLevers,
      saveChanges: {},
      leverStore,
      isAdmin: true
    };

    setup(testProps);

    expect(screen.getByText('Administration')).toBeInTheDocument();
    expect(screen.getByText('Case Distribution Algorithm Values')).toBeInTheDocument();
    expect(screen.getByText('AMA Non-priority Distribution Goals by Docket')).toBeInTheDocument();
    expect(screen.getByText('Active Data Elements')).toBeInTheDocument();
    expect(screen.getByText('Inactive Data Elements')).toBeInTheDocument();
    expect(screen.getByText('Case Distribution Algorithm Change History')).toBeInTheDocument();
  });

  it('renders the "CaseDistributionContent Component" with the exclude from affinity banner enabled', () => {

    store.dispatch(loadAcdExcludeFromAffinity(true));

    render(
      <BrowserRouter>
        <Provider store={store}>
          <CaseDistributionContent />
        </Provider>
      </BrowserRouter>
    );

    expect(
      screen.getByText('may remove individual judges from Affinity Case Distribution', { exact: false })
    ).toBeInTheDocument();
  });

  it('renders the "CaseDistributionContent Component" without the exclude from affinity banner enabled', () => {

    store.dispatch(loadAcdExcludeFromAffinity(false));

    render(
      <BrowserRouter>
        <Provider store={store}>
          <CaseDistributionContent />
        </Provider>
      </BrowserRouter>
    );

    expect(screen.queryByText('may remove individual judges from Affinity Case Distribution')).not.toBeInTheDocument();
  });

});
