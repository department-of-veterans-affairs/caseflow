import React from 'react';
import PropTypes from 'prop-types';

// components
import StyleGuideIndex from './StyleGuide/StyleGuideIndex';
import TestPage from './TestPage';
import Intake from '../intake';
import Reader from '../reader/index';

const Pages = {
  DecisionReviewer: Reader,
  Intake,
  StyleGuideIndex,
  TestPage
};

// This is the "base page" that wraps pages rendered directly
// in a Rails view. This component manages interactivity that exists
// across React pages imported.
//
// The `page` property dictates which page is rendered within this
// component. e.g.  <BaseContainer page="StyleGuideIndex" />

export default class BaseContainer extends React.Component {
  constructor(props) {
    super(props);
    window.jqueryOn = false;
  }

  render() {
    // `rest` signifies all the props passed in from Rails that
    // we want to send directly to the PageComponent
    let { page, ...rest } = this.props;
    let PageComponent = Pages[page];

    return <PageComponent {...rest} />;
  }
}

BaseContainer.propTypes = {
  page: PropTypes.string.isRequired
};
