import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import LoadingContainer from '../components/LoadingContainer';
import StatusMessage from '../components/StatusMessage';
import * as AppConstants from '../constants/AppConstants';
import { TOGGLE_DOCKET_SAVING, SET_EDITED_FLAG_TO_FALSE, SET_DOCKET_SAVE_FAILED } from './constants/constants';
import AutoSave from '../components/AutoSave';
import DailyDocket from './DailyDocket';
import ApiUtil from '../util/ApiUtil';

export class DailyDocketContainer extends React.Component {

  componentDidMount() {
    this.props.getDockets();
  }

  docket = () => {
    return this.props.dockets[this.props.date].hearings_array;
  }

  render() {
    if (this.props.docketServerError) {
      return <StatusMessage
        title="Unable to load hearings">
          It looks like Caseflow was unable to load hearings.<br />
          Please <a href="">refresh the page</a> and try again.
      </StatusMessage>;
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

    return <div className="cf-hearings-daily-docket-container">
      <AutoSave
        save={this.props.save(this.docket(), this.props.date)}
        spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
        isSaving={this.props.docketIsSaving}
        saveFailed={this.props.saveDocketFailed}
      />
      <DailyDocket
        veteran_law_judge={this.props.veteran_law_judge}
        date={this.props.date}
        docket={this.docket()}
      />
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets,
  docketServerError: state.docketServerError
});

const mapDispatchToProps = (dispatch) => ({
  getDockets: (dockets) => () => {
    if (!dockets) {
      ApiUtil.get('/hearings/dockets.json', { cache: true }).
        then((response) => {
          dispatch(Actions.populateDockets(response.body));
        }, (err) => {
          dispatch(Actions.handleDocketServerError(err));
        });
    }
  },
  save: (docket, date) => () => {
    const hearingsToSave = docket.filter((hearing) => hearing.edited);

    if (hearingsToSave.length === 0) {
      return;
    }

    dispatch({ type: TOGGLE_DOCKET_SAVING });

    dispatch({ type: SET_DOCKET_SAVE_FAILED,
      payload: { saveFailed: false } });

    hearingsToSave.forEach((hearing) => {

      const index = docket.findIndex((x) => x.id === hearing.id);

      ApiUtil.patch(`/hearings/${hearing.id}`, { data: { hearing } }).
        then(() => {
          dispatch({ type: SET_EDITED_FLAG_TO_FALSE,
            payload: { date,
              index } });
        },
        () => {
          dispatch({ type: SET_DOCKET_SAVE_FAILED,
            payload: { saveFailed: true } });
        });
    });
    dispatch({ type: TOGGLE_DOCKET_SAVING });
  }
});

const mergeProps = (stateProps, dispatchProps, ownProps) => {
  return {
    ...stateProps,
    ...dispatchProps,
    ...ownProps,
    getDockets: dispatchProps.getDockets(stateProps.dockets)
  };
};

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DailyDocketContainer);

DailyDocketContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  dockets: PropTypes.object,
  date: PropTypes.string.isRequired,
  docketServerError: PropTypes.object
};
