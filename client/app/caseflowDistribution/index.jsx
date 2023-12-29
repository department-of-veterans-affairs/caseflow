import React from 'react';
import ReduxBase from '../components/ReduxBase';
import caseflowDistributionReducer, { initialState } from './reducers';
import { Router } from 'react-router';
import { createBrowserHistory } from 'history';

import CaseflowDistributionApp from './caseflowDistributionApp';

const history = createBrowserHistory();

const CaseflowDistribution = (props) => {
  return (
    <ReduxBase
      reducer={caseflowDistributionReducer}
      initialState={{ ...initialState }}
      thunkArgs={{ history }}
    >
      <Router history={history}>
        <CaseflowDistributionApp {...props} />
      </Router>
    </ReduxBase>
  );
};

export default CaseflowDistribution;
