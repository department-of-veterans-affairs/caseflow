import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { fetchFlaggedForReview } from './actions';
import LoadingContainer from '../components/LoadingContainer';
import FlaggedForReview from './FlaggedForReview';

export class FlaggedForReviewContainer extends Component {
  componentDidMount() {
    this.props.fetchFlaggedForReview();
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

    return <FlaggedForReview {...this.props} />;
  }
}

const mapStateToProps = (state) => {
  return {
    loading: state.loading,
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
