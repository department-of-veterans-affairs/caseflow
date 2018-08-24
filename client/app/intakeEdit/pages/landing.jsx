import React, { Component } from 'react';
import { connect } from 'react-redux';

class Landing extends Component {
  render() {
    return <div>
      Hello {this.props.veteranFormName}
    </div>;
  }
}

export default connect(
  ({ veteran }) => ({
    veteranFormName: veteran.formName,
    veteranFileNumber: veteran.fileNumber
  })
)(Landing);
