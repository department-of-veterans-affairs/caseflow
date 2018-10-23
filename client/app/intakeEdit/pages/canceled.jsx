import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import StatusMessage from '../../components/StatusMessage';
import { FORM_TYPES } from '../../intake/constants';

class Canceled extends Component {
  render = () => {
    const {
      veteran,
      formType
    } = this.props;
    const formName = _.find(FORM_TYPES, { key: formType }).name;
    const message = `No changes were made to ${veteran.name}'s (ID #${veteran.fileNumber}) Request for ${formName}.
Go to VBMS claim details and click the “Edit in Caseflow” button to return to edit.`;

    return <div>
      <StatusMessage
        title="Edit Canceled"
        leadMessageList={[message]}
      />
    </div>;
  }
}

Canceled.propTypes = {
  veteran: PropTypes.object.isRequired,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')).isRequired
};

export default connect(
  (state) => ({
    veteran: state.veteran,
    formType: state.formType
  })
)(Canceled);
