import React, { Component } from 'react';
import { connect } from 'react-redux';

class SelectIssues extends Component {
  render() {
    return <div>
      What up {this.props.veteran.formName}
    </div>;
  }
}

export default connect(
  ({ veteran }) => ({
    veteran
  })
)(SelectIssues);
