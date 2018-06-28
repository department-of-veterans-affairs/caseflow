import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { onReceivePastUploads } from '../actions';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';

class LoadingScreen extends React.PureComponent {
  loadPastUploads = () => {
    if (!_.isEmpty(this.props.pastUploads)) {
      return Promise.resolve();
    }

    return ApiUtil.get('/hearings/schedule_periods.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      const schedulePeriods = _.keyBy(resp.schedulePeriods, 'id');

      this.props.onReceivePastUploads({ pastUploads: schedulePeriods });
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
        message: 'Loading the hearing schedule...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the hearing schedule.'
      }}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceivePastUploads
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(LoadingScreen);
