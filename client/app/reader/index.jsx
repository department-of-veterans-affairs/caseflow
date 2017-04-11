import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import { createStore } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';

function readerReducer(state = {}, action = {}) {
    return state;
}

const store = createStore(readerReducer);

export default (props) => {
    return <Provider store={store}>
        <DecisionReviewer {...props} />
    </Provider>;
};