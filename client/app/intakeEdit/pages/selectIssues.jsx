import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import RatedIssuesUnconnected from '../../intakeCommon/components/RatedIssues';
import { setIssueSelected } from '../../intake/actions/ama';
import { FORM_TYPES } from '../../intake/constants';

// This page shouldn't matter that much which type of Review it is.
class SelectIssues extends React.PureComponent {
  render() {
    const {
      veteranName,
      formType
    } = this.props;

    const reviewForm = _.find(FORM_TYPES, { key: formType });

    return <div>
      <h1>Issues on { veteranName }'s { reviewForm.name }</h1>

      <p>
        Please select all the issues that best match the Veteran's request on the form.
        The list below includes issues claimed by the Veteran in the last year.
      </p>

      <RatedIssues />

    </div>;
  }
}

const RatedIssues = connect(
  ({ ratings }) => ({
    ratings
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssuesUnconnected);

export default connect(
  (state) => ({
    veteranName: state.veteran.name,
    formType: state.formType
  })
)(SelectIssues);
