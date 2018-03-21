import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import DecisionReviewer from './DecisionReviewer';

import { BrowserRouter, Route, Switch } from 'react-router-dom';
import rootReducer from './reducers';

class Reader extends React.PureComponent {
  constructor() {
    super();
    this.routedDecisionReviewer.displayName = 'RoutedDecisionReviewer';
  }

  routedDecisionReviewer = () => <DecisionReviewer {...this.props} />;

  render = () => {
    const Router = this.props.router || BrowserRouter;

    return <ReduxBase reducer={rootReducer}>
      <Router basename="/reader/appeal" {...this.props.routerTestProps}>
        <Switch>
          {/* We want access to React Router's match params, so we'll wrap all possible paths in a <Route>. */}
          <Route path="/:vacolsId/documents" render={this.routedDecisionReviewer} />
          <Route path="/" render={this.routedDecisionReviewer} />
        </Switch>
      </Router>
    </ReduxBase>;
  };
}

export default Reader;
