import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../util/ApiUtil';
import { getWorksheetAppealsAndIssues } from '../utils';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import HearingWorksheetPrinted from '../components/hearingWorksheet/HearingWorksheetPrinted';

const failedToLoad = <div><p>Failed to load</p></div>;

class HearingWorksheetPrintAllContainer extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      worksheets: []
    };
  }

  loadHearingWorksheets = () => {
    let { hearingIds } = this.props;
    let getAllWorksheets = hearingIds.map(
      (hearingId) => ApiUtil.get(`/hearings/${hearingId}/worksheet.json`)
    );

    return Promise.all(getAllWorksheets).then((responses) => {
      this.setState({
        worksheets: responses.map((response) => getWorksheetAppealsAndIssues(response.body))
      });
    });
  };

  render() {
    return (
      <React.Fragment>
        <LoadingDataDisplay
          createLoadPromise={this.loadHearingWorksheets}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
            message: 'Loading the hearing worksheet...'
          }}
          failStatusMessageProps={{
            title: 'Unable to load the hearing worksheet.'
          }}
          failStatusMessageChildren={failedToLoad}
        >
          {
            this.state.worksheets &&
            this.state.worksheets.map(
              (worksheetProps) => (
                <div className="cf-printed-worksheet" key={worksheetProps.worksheet.external_id}>
                  <HearingWorksheetPrinted {...worksheetProps} updateTitle={false} />
                </div>
              )
            )
          }
        </LoadingDataDisplay>
      </React.Fragment>
    );
  }
}

HearingWorksheetPrintAllContainer.propTypes = {
  hearingIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default HearingWorksheetPrintAllContainer;
