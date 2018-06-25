import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { onReceivePastUploads } from '../actions';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';

class LoadingScreen extends React.PureComponent {
  loadPastUploads = () => {
    if (!_.isEmpty(this.props.pastUploads)) {
      return Promise.resolve();
    }

    return this.props.onReceivePastUploads({
      pastUploads: [
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'Judge',
          createdAt: '07/03/2018',
          user: 'Justin Madigan',
          fileName: 'fake file name'
        },
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'RO/CO',
          createdAt: '07/03/2018',
          user: 'Justin Madigan',
          fileName: 'fake file name'
        }
      ]
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
