const configureStore = (reducers, initialData, moreMiddleware) => {
  // This is to be used with the Redux Devtools Chrome extension
  // https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const middleware = [];

  if (!ConfigUtil.test()) {
    middleware.push(thunk, perflogger);
  }

  if (moreMiddleware) {
    middleware = middleware.concat(moreMiddleware);
  }

  const enhancers  = composeEnhancers(applyMiddleware(middleware));

  if (initialData) {
    const store = createStore(
      reducers,
      initialData,
      enhancers
    );
  } else {
    const store = createStore(
      reducers,
      enhancers
    );
  }

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./reducer', () => {
      store.replaceReducer(reducers);
    });
  }

  return store;
}

export configureStore;
