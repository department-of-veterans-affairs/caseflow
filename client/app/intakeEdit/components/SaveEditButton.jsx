import React from 'react';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { REQUEST_STATE } from '../../intake/constants';

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
