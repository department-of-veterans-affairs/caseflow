import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { fetchIntakesForReview } from './actions';
import LoadingContainer from '../components/LoadingContainer';
import IntakesForReview from './IntakesForReview';

export class IntakesForReviewContainer extends Component {
  componentDidMount() {
    this.props.fetchIntakesForReview();
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

    return <IntakesForReview {...this.props} />;
  }
}

const mapStateToProps = (state) => {
  return {
    loading: state.loading,
    intakes: state.intakesForReview
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchIntakesForReview
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(IntakesForReviewContainer);
