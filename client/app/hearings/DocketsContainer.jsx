import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import * as AppConstants from '../constants/AppConstants';
import LoadingContainer from '../components/LoadingContainer';
import Dockets from './Dockets';
import ApiUtil from '../util/ApiUtil';

export const getDockets = (dispatch) => {
  ApiUtil.get('/hearings/dockets.json', { cache: true }).
    then((response) => {
      dispatch(Actions.populateDockets(response.body));
    }, (err) => {
      dispatch(Actions.handleServerError(err));
    });
};

export class DocketsContainer extends React.Component {

  componentDidMount() {
    if (!this.props.dockets) {
      this.props.getDockets();
    }

      // Since the title may have changed before rendering...
    const pageTitle = document.getElementById('page-title');

    if (pageTitle) {
      pageTitle.innerHTML = '';
    }
  }

  render() {

    if (this.props.serverError) {
      return <div style={{ textAlign: 'center' }}>
        An error occurred while retrieving your hearings.</div>;
    }

    if (!this.props.dockets) {
      return <div className="loading-hearings">
        <div className="cf-sg-loader">
          <LoadingContainer color={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading dockets, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    if (Object.keys(this.props.dockets).length === 0) {
      return <div>You have no upcoming hearings.</div>;
    }

    return <Dockets {...this.props} />;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets,
  serverError: state.serverError
});

const mapDispatchToProps = (dispatch) => ({
  getDockets: () => {
    getDockets(dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocketsContainer);

DocketsContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  dockets: PropTypes.object,
  serverError: PropTypes.object
};
