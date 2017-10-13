import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as AppConstants from '../constants/AppConstants';
import { fetchStuckTasks } from './actions';
import LoadingContainer from '../components/LoadingContainer';
import StuckTasks from './StuckTasks';

// This page shows appeals that are "stuck" in Caseflow Dispatch.
// This is typically because the sensitivity level is too high
// for any AMC worker
export class StuckTasksContainer extends Component {
  componentDidMount() {
    this.props.fetchStuckTasks();
  }

  render() {
    if (this.props.loading) {
      return <div className="loading-dispatch">
        <div className="cf-sg-loader">
          <LoadingContainer color={AppConstants.LOADING_INDICATOR_COLOR_DISPATCH}>
              <div className="cf-image-loader">
              </div>
            <p className="cf-txt-c">Loading, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    return <StuckTasks {...this.props}/>;
  }
}

const mapStateToProps = (state) => {
  return {
    loading: state.loading,
    tasks: state.stuckTasks
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchStuckTasks
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(StuckTasksContainer);
