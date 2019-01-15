import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

class HearingDetails extends React.Component {

  render() {
    console.log(this.props);

    return (
      <AppSegment />
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired
};

export default connect(
  null
)(HearingDetails);
