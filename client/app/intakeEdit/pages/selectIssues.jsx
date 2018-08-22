import React, { Component } from 'react';
import { connect } from 'react-redux';

class SelectIssues extends Component {
  render() {
    return <div>
      What up {this.props.veteranFormName}
    </div>;
  }
}

export default connect(
  ({ veteran }) => ({
    veteranFormName: veteran.formName,
    veteranFileNumber: veteran.fileNumber
  })
)(SelectIssues);
