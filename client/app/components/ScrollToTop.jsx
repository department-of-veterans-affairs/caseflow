import React from 'react';
import { withRouter } from 'react-router-dom';

class ScrollToTop extends React.Component {
  componentDidUpdate = (prevProps) => {
    if (prevProps.location !== this.props.location) {
      window.scrollTo(0, 0);
    }
  }

  render = () => null;
}

export default withRouter(ScrollToTop);
