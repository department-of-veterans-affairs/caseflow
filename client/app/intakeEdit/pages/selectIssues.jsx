import React, { Component } from 'react';
import { connect } from 'react-redux';

class SelectIssues extends Component {
  render() {
    return <div>
      What up {this.props.review.veteranFormName}
    </div>;
  }
}

export default connect(
  ({ review }) => ({
    review
  })
)(SelectIssues);
