import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';

function readerReducer(state = {}, action = {}) {
    return state;
}

const store = createStore(readerReducer, null, applyMiddleware(logger));

export default (props) => {
    return <Provider store={store}>
        <DecisionReviewer {...props} />
    </Provider>;
};