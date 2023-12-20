/* eslint-disable react/prop-types */
import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { fetchFlaggedForReview } from './actions';
import LoadingContainer from '../components/LoadingContainer';
import FlaggedForReview from './FlaggedForReview';
import UserStats from './UserStats';

export class FlaggedForReviewContainer extends Component {
  componentDidMount() {
    // deprecated - may remove
    // this.props.fetchFlaggedForReview();
  }

  render() {
    if (this.props.loading) {
      return <div className="loading-dispatch">
        <div className="cf-sg-loader">
          <LoadingContainer color={LOGO_COLORS.INTAKE.ACCENT}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    return <div>
      <UserStats selectedUser={this.props.selectedUser} />
      <FlaggedForReview {...this.props} />
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    loading: false,
    // loading: state.loading,
    intakes: state.flaggedForReview
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchFlaggedForReview
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(FlaggedForReviewContainer);
