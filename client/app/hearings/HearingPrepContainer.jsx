import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Route, BrowserRouter } from 'react-router-dom';
import { prepSaveData } from './utils';
import ApiUtil from '../util/ApiUtil';
import DocketsContainer from './DocketsContainer';
import DailyDocketContainer from './DailyDocketContainer';
import HearingWorksheetContainer from './HearingWorksheetContainer';

export const saveBeforeWindowCloses = () => (dispatch, getState) => {
  const dataToSave = prepSaveData(getState().save);

  ApiUtil.post(
    '/hearings/save_data', { data: dataToSave }
  ).then(
    // w/o then(), POST request seems to fail
  );
};

export class HearingPrepContainer extends React.PureComponent {

  componentDidMount = () => {
    window.onbeforeunload = () => {
      this.props.saveBeforeWindowCloses();
    };
  }

  render() {
    return <div>
      <BrowserRouter>
        <div>
          <Route exact path="/hearings/dockets"
            component={() => (
              <DocketsContainer
                veteran_law_judge={this.props.hearings.veteran_law_judge} />
            )}
          />
          <Route exact path="/hearings/dockets/:date"
            component={(props) => (
              <DailyDocketContainer
                veteran_law_judge={this.props.hearings.veteran_law_judge}
                date={props.match.params.date} />
            )}
          />
          <Route exact path="/hearings/:hearing_id/worksheet"
            component={(props) => (
              <HearingWorksheetContainer
                veteran_law_judge={this.props.hearings.veteran_law_judge}
                hearing_id={props.match.params.hearing_id} />
            )}
          />
        </div>
      </BrowserRouter>
    </div>;
  }
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => ({
  saveBeforeWindowCloses: () => {
    dispatch(saveBeforeWindowCloses());

    return true;
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingPrepContainer);

HearingPrepContainer.propTypes = {
  hearings: PropTypes.object
};
