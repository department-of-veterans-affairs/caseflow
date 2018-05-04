import React from 'react';

export default class ScrollToTop extends React.Component {
  componentDidUpdate = () => window.scrollTo(0, 0);

  render = () => null;
}
