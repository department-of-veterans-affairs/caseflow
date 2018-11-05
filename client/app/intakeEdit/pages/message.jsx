import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import StatusMessage from '../../components/StatusMessage';
import { FORM_TYPES } from '../../intake/constants';

class ClearedEndProducts extends Component {
  render = () => {
    const {
      veteran,
      formType,
      displayMessage,
      title
    } = this.props;


    const formName = _.find(FORM_TYPES, { key: formType }).name;
    // const message = `Other end products associated with this ${formName} have already been decided, 
    //     so issues are no longer editable. If this is a problem, please contact Caseflow support.`;
    const message = displayMessage({formName: formName, veteran: veteran});

    return <div>
      <StatusMessage
        title={title}
        leadMessageList={[message]}
      />
    </div>;
  }
}

ClearedEndProducts.propTypes = {
  veteran: PropTypes.object.isRequired,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')).isRequired,
  title: PropTypes.string.isRequired,
  displayMessage: PropTypes.func.isRequired
};

export default connect(
  (state) => ({
    veteran: state.veteran,
    formType: state.formType
  })
)(ClearedEndProducts);
