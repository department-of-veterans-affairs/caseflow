import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { onReceivePastUploads, unsetSuccessMessage } from '../actions';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';
import BuildSchedule from '../components/BuildSchedule';

class BuildScheduleContainer extends React.PureComponent {

  componentWillUnmount() {
    this.props.unsetSuccessMessage();
  }

  loadPastUploads = () => {
    if (!_.isEmpty(this.props.pastUploads)) {
      return Promise.resolve();
    }

    return ApiUtil.get('/hearings/schedule_periods.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      const schedulePeriods = _.keyBy(resp.schedulePeriods, 'id');

      this.props.onReceivePastUploads(schedulePeriods);
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadPastUploads()
  ]);

  render = () => {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading past schedule uploads...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load past schedule uploads.'
      }}>
      <BuildSchedule
        pastUploads={this.props.pastUploads}
        schedulePeriod={this.props.schedulePeriod}
        displaySuccessMessage={this.props.displaySuccessMessage}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  pastUploads: state.pastUploads,
  schedulePeriod: state.schedulePeriod,
  displaySuccessMessage: state.displaySuccessMessage
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceivePastUploads,
  unsetSuccessMessage
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(BuildScheduleContainer);
