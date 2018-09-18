import React from 'react';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import RatedIssuesUnconnected from '../../intakeCommon/components/RatedIssues';
import { setIssueSelected } from '../../intake/actions/ama';
import { requestIssuesUpdate } from '../actions/selectIssues';
import { FORM_TYPES } from '../../intakeCommon/constants';
import CancelEdit from '../components/CancelEdit';
import { REQUEST_STATE } from '../constants';

// This page shouldn't matter that much which type of Review it is.
class SelectIssues extends React.PureComponent {
  render() {
    const {
      veteranName,
      formType,
      requestStatus,
      responseErrorData,
      responseErrorCode
    } = this.props;

    const reviewForm = _.find(FORM_TYPES, { key: formType });

    return <div>
      <h1>Issues on { veteranName }'s { reviewForm.name }</h1>

      <p>status of request: { requestStatus }</p>
      <p>response data: { responseErrorData }</p>
      <p>response code: { responseErrorCode }</p>
      <p>
        Please select all the issues that best match the Veteran's request on the form.
        The list below includes issues claimed by the Veteran in the last year.
      </p>

      <RatedIssues />

    </div>;
  }
}

class SaveButtonUnconnected extends React.PureComponent {
  handleClick = () => {
    this.props.requestIssuesUpdate(this.props.claimId, this.props.formType, {
      ratings: this.props.ratings,
      nonRatedIssues: this.props.nonRatedIssues
    });
  }

  render = () =>
    <Button
      name="submit-update"
      onClick={this.handleClick}
      loading={this.props.requestStatus.requestIssuesUpdate === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      Save
    </Button>;
}

const SaveButton = connect(
  ({ review, formType, requestStatus, ratings }) => ({
    claimId: review.claimId,
    formType,
    requestStatus,
    ratings
  }),
  (dispatch) => bindActionCreators({
    requestIssuesUpdate
  }, dispatch)
)(SaveButtonUnconnected);

const RatedIssues = connect(
  ({ ratings }) => ({
    ratings
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssuesUnconnected);

export class SelectIssuesButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelEdit />
      <SaveButton />
    </div>
}

export default connect(
  (state) => ({
    veteranName: state.review.veteranName,
    formType: state.formType,
    requestStatus: state.requestStatus.requestIssuesUpdate,
    responseErrorCode: state.responseErrorCode,
    responseErrorData: state.responseErrorData
  })
)(SelectIssues);
