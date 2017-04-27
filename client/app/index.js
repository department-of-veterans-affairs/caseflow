import React from 'react';
import ReactOnRails from 'react-on-rails';
import { render } from 'react-dom';
import { AppContainer } from 'react-hot-loader';
import _ from 'lodash';

// List of container components we render directly in  Rails .erb files
import BaseContainer from './containers/BaseContainer';
import Certification from './certification/Certification';

const COMPONENTS = {
  BaseContainer,
  Certification
};

const componentWrapper = (component) => (props, railsContext, domNodeId) => {
  const renderApp = (Component) => {
    const element = (
      <AppContainer>
        <Component {...props}/>
      </AppContainer>
    );

    render(element, document.getElementById(domNodeId));
  };

  renderApp(component);

  if (module.hot) {
    module.hot.accept([
      './containers/BaseContainer',
      './certification/Certification'
    ], () => renderApp(component));
  }
};

_.forOwn(COMPONENTS, (component, name) => {
  ReactOnRails.register({ [name]: componentWrapper(component) });
});

