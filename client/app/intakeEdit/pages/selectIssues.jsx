import React from 'react';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import RatedIssuesUnconnected from '../../intakeCommon/components/RatedIssues';
import { setIssueSelected } from '../../intake/actions/ama';
import { requestIssuesUpdate } from '../actions/selectIssues';
import { FORM_TYPES, REQUEST_STATE } from '../../intakeCommon/constants';
import CancelEdit from '../components/CancelEdit';
import RequestIssuesUpdateErrorAlert from '../components/RequestIssuesUpdateErrorAlert';

// This page shouldn't matter that much which type of Review it is.
class SelectIssues extends React.PureComponent {
  render() {
    const {
      veteranName,
      formType,
      responseErrorCode
    } = this.props;

    const reviewForm = _.find(FORM_TYPES, { key: formType });

    return <div>
      <h1>Issues on { veteranName }'s { reviewForm.name }</h1>

      { responseErrorCode &&
        <RequestIssuesUpdateErrorAlert responseErrorCode={responseErrorCode} />
      }

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
      ratings: this.props.ratings
    }).then(() => this.props.history.push('/'));
  }

  render = () =>
    <Button
      name="submit-update"
      onClick={this.handleClick}
      loading={this.props.requestStatus.requestIssuesUpdate === REQUEST_STATE.IN_PROGRESS}
      disabled={!this.props.ratingsChanged}
    >
      Save
    </Button>;
}

const SaveButton = connect(
  ({ review, formType, requestStatus, ratings, ratingsChanged }) => ({
    claimId: review.claimId,
    formType,
    requestStatus,
    ratings,
    ratingsChanged
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
      <CancelEdit history={this.props.history} />
      <SaveButton history={this.props.history} />
    </div>
}

export default connect(
  (state) => ({
    veteranName: state.review.veteranName,
    formType: state.formType,
    requestStatus: state.requestStatus.requestIssuesUpdate,
    responseErrorCode: state.responseErrorCode
  })
)(SelectIssues);
