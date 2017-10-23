import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import * as AppConstants from '../constants/AppConstants';
import LoadingContainer from '../components/LoadingContainer';
import Alert from '../components/Alert';
import Dockets from './Dockets';
import ApiUtil from '../util/ApiUtil';

export const getDockets = (dispatch) => {
  ApiUtil.get('/hearings/dockets.json', { cache: true }).
    then((response) => {
      dispatch(Actions.populateDockets(response.body));
    }, (err) => {
      dispatch(Actions.handleDocketServerError(err));
    });
};

export class DocketsContainer extends React.Component {

  componentDidMount() {
    if (!this.props.dockets) {
      this.props.getDockets();
    }
  }

  render() {

    if (this.props.docketServerError) {
      return <div className="cf-app-segment cf-app-segment--alt cf-hearings">
        <Alert
          title="Unable to load documents"
          type="error">It looks like Caseflow was unable to load hearings.
          Please refresh the page and try again.
        </Alert>
      </div>;
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
  docketServerError: state.docketServerError
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
  docketServerError: PropTypes.object
};
