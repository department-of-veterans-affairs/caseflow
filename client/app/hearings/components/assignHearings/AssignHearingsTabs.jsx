import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { getQueryParams } from '../../../util/QueryParamsUtil';

import AssignHearingsTable from './AssignHearingsTable';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG';
import TabWindow from '../../../components/TabWindow';
import UpcomingHearingsTable from './UpcomingHearingsTable';

// Gets the tab index based off the tab parameter in the query string.
// The indexes are based on the ordering of the tabs in the AssignHearingsTabs component.
const getCurrentTabIndex = () => {
  const tabParam = getQueryParams(window.location.search)[QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM];

  if (tabParam === QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME) {
    return 1;
  } else if (tabParam === QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME) {
    return 2;
  }

  return 0;
};

export default class AssignHearingsTabs extends React.PureComponent {
  onTabChange = (tabNumber) => {
    this.setState({ clickedTab: tabNumber });
  }

  render() {
    const {
      selectedHearingDay,
      selectedRegionalOffice,
      room,
      defaultTabIndex
    } = this.props;

    const hearingsForSelected = _.get(selectedHearingDay, 'hearings', {});
    const availableSlots = _.get(selectedHearingDay, 'totalSlots', 0) - Object.keys(hearingsForSelected).length;

    return (
      <div className="usa-width-three-fourths assign-hearing-tabs">
        {!_.isNil(selectedHearingDay) &&
          <h1>
            {`${moment(selectedHearingDay.scheduledFor).format('ddd M/DD/YYYY')}  
              ${room ?? ''} (${availableSlots} slots remaining)`}
          </h1>
        }
        <TabWindow
          name="scheduledHearings-tabwindow"
          defaultPage={defaultTabIndex}
          onChange={this.onTabChange}
          tabs={[
            {
              label: 'Scheduled Veterans',
              page: <UpcomingHearingsTable
                selectedRegionalOffice={selectedRegionalOffice}
                selectedHearingDay={selectedHearingDay}
                hearings={hearingsForSelected}
              />
            },
            {
              label: 'Legacy Veterans Waiting',
              page: <AssignHearingsTable
                selectedHearingDay={selectedHearingDay}
                selectedRegionalOffice={selectedRegionalOffice}
                tabName={QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME}
                key={QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME}
                clicked={this.state && this.state.clickedTab === 1}
              />
            },
            {
              label: 'AMA Veterans Waiting',
              page: <AssignHearingsTable
                selectedHearingDay={selectedHearingDay}
                selectedRegionalOffice={selectedRegionalOffice}
                tabName={QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}
                key={QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}
                clicked={this.state && this.state.clickedTab === 2}
              />
            }
          ]}
        />
      </div>
    );
  }
}

AssignHearingsTabs.propTypes = {
  defaultTabIndex: PropTypes.number,
  selectedHearingDay: PropTypes.shape({
    hearings: PropTypes.object,
    id: PropTypes.number,
    regionalOffice: PropTypes.string,
    regionalOfficeKey: PropTypes.string,
    requestType: PropTypes.string,
    room: PropTypes.string,
    scheduledFor: PropTypes.string,
    totalSlots: PropTypes.number
  }),

  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,

  room: PropTypes.string
};

AssignHearingsTabs.defaultProps = {
  defaultTabIndex: getCurrentTabIndex()
};
