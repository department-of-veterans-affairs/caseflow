import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import LoadingContainer from '../components/LoadingContainer';
import * as AppConstants from '../constants/AppConstants';
import { TOGGLE_SAVING, SET_EDITED_FLAG_TO_FALSE } from './constants/constants';
import AutoSave from '../components/AutoSave.jsx';
import DailyDocket from './DailyDocket';
import ApiUtil from '../util/ApiUtil';

export class DailyDocketContainer extends React.Component {

  componentDidMount() {
    this.props.getDockets();

    // Since the page title does not change when react router
    // renders this component...
    const pageTitle = document.getElementById('page-title');

    if (pageTitle) {
      pageTitle.innerHTML = ' | Daily Docket';
    }
  }

  docket = () => {
    return this.props.dockets[this.props.date].hearings_array;
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

    return <div className="cf-hearings-daily-docket-container">
      <AutoSave
        save={this.props.save(this.docket(), this.props.date)}
        spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
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
  serverError: state.serverError
});

const mapDispatchToProps = (dispatch) => ({
  getDockets: (dockets) => () => {
    if (!dockets) {
      ApiUtil.get('/hearings/dockets.json', { cache: true }).
        then((response) => {
          dispatch(Actions.populateDockets(response.body));
        }, (err) => {
          dispatch(Actions.handleServerError(err));
        });
    }
  },
  save: (docket, date) => () => {
    const hearingsToSave = docket.filter((hearing) => hearing.edited);

    let hearingsToSaveIndeces = [];

    for (let index = 0; index < docket.length; index++) {
      if (docket[index].edited) {
        hearingsToSaveIndeces.push(index);
      }
    }

    if (hearingsToSave.length) {
      dispatch({ type: TOGGLE_SAVING });

      // ApiUtil.put('/hearings/save_data', { data: { hearings: hearingsToSave} }).
      //   then(
      //     () => {
      //       dispatch({ type: TOGGLE_SAVING });
      //
      //       hearingsToSaveIndeces.forEach((index) => {
      //         dispatch({ type: SET_EDITED_FLAG_TO_FALSE, payload: { date, index }})
      //       });
      //     },
      //     (err) => {
      //       dispatch({ type: TOGGLE_SAVING });
      //       dispatch(handleServerError(err));
      //     }
      //   );

      // instead of mocking ApiUtil somehow, assume a PUT request succeeds after 1 second
      setTimeout(() => {
        dispatch({ type: TOGGLE_SAVING });

        hearingsToSaveIndeces.forEach((index) => {
          dispatch({
            type: SET_EDITED_FLAG_TO_FALSE,
            payload: {
              date,
              index
            }
          });
        });
      }, 1000);
    }
  }
});

const mergeProps = (stateProps, dispatchProps, ownProps) => {
  return {
    ...stateProps,
    ...dispatchProps,
    ...ownProps,
    getDockets: dispatchProps.getDockets(stateProps.docket)
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
  serverError: PropTypes.object
};
