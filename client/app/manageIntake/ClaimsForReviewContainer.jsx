import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { fetchClaimsForReview } from './actions';
import LoadingContainer from '../components/LoadingContainer';
import ClaimsForReview from './ClaimsForReview';

export class ClaimsForReviewContainer extends Component {
  componentDidMount() {
    this.props.fetchClaimsForReview();
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

    return <ClaimsForReview {...this.props} />;
  }
}

const mapStateToProps = (state) => {
  return {
    loading: state.loading,
    claims: state.claimsForReview
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchClaimsForReview
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ClaimsForReviewContainer);
