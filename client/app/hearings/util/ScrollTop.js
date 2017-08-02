import { Component } from 'react';
import { withRouter } from 'react-router-dom';

class ScrollToTop extends Component {
  // eslint-disable-next-line class-methods-use-this
  componentDidUpdate() {
    window.scrollTo(0, 0);
  }
  // eslint-disable-next-line class-methods-use-this
  render() {
    return null;
  }
}

export default withRouter(ScrollToTop);
