import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter, Route, Switch } from 'react-router-dom';

import ReduxBase from '../components/ReduxBase';
import DecisionReviewer from './DecisionReviewer';
import rootReducer from './reducers';

class Reader extends React.PureComponent {
  constructor() {
    super();
    this.routedDecisionReviewer.displayName = 'RoutedDecisionReviewer';
  }

  routedDecisionReviewer = () => <DecisionReviewer {...this.props} />;

  render = () => {

    return (
      <ReduxBase reducer={rootReducer}>
        <BrowserRouter basename="/reader/appeal" {...this.props.routerTestProps}>
          <Switch>
            {/* We want access to React Router's match params, so we'll wrap all possible paths in a <Route>. */}
            <Route path="/:vacolsId/documents" render={this.routedDecisionReviewer} />
            <Route path="/" render={this.routedDecisionReviewer} />
          </Switch>
        </BrowserRouter>
      </ReduxBase>
    );
  };
}

Reader.propTypes = {
  router: PropTypes.elementType,
  routerTestProps: PropTypes.object
};

export default Reader;
