import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perfLogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';

import { getReduxAnalyticsMiddleware } from './getReduxAnalyticsMiddleware';

export default class ReduxBase extends React.PureComponent {
  componentWillMount() {
    // eslint-disable-next-line no-underscore-dangle
    const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

    const store = createStore(
      this.props.reducer,
      this.props.initialState,
      composeEnhancers(
        applyMiddleware(thunk, perfLogger, getReduxAnalyticsMiddleware(...this.props.analyticsMiddlewareArgs)),
        ...this.props.enhancers
      )
    );

    this.setState({ store });
  }

  render = () =>
    <Provider store={this.state.store}>
      {this.props.children}
    </Provider>;
}

ReduxBase.defaultProps = {
  analyticsMiddlewareArgs: [],
  enhancers: []
};
