import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import Table from '../../components/Table';
import { formatDateStr } from '../../util/DateUtil';
import RoSelectorDropdown from './RoSelectorDropdown';
import { css } from 'glamor';
import classnames from 'classnames';

const bottomMargin = css({
  color: 'red'
});

export default class AssignHearings extends React.Component {

  onSelectedHearingDayChange = (hearingDay) => () => {
    this.props.onSelectedHearingDayChange(hearingDay);
  };

  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth">
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list">
        {Object.values(this.props.upcomingHearingDays).slice(0, 9).
          map((hearingDay) => {
            const availableSlots = hearingDay.totalSlots - Object.keys(hearingDay.hearings).length;

            return <li key={hearingDay.id} >
              <Button
                onClick={this.onSelectedHearingDayChange(hearingDay)}
                linkStyling
              >
                {`${formatDateStr(hearingDay.hearingDate)} ${hearingDay.roomInfo} (${availableSlots} slots)`}
              </Button>
            </li>;
          })}
      </ul>
    </div>;
  };

  veteranTypeColor = (type) => {
    let veteranType;
     if (type  === 'CAVC') {
      veteranType = <span {...bottomMargin}>CAVC</span>;
     } else if (type === 'AOD') {
       veteranType = <span {...bottomMargin}>AOD</span>;
   }
     return veteranType;
   }

  tableRows = (veterans) => {
    return _.map(veterans, (veteran) => ({
      caseDetails: veteran.name,
      type: this.veteranTypeColor(veteran.type),
      docketNumber: veteran.docketNumber,
      location: veteran.location,
      time: veteran.time
    }));
  };

  veteransReadyForHearing = () => {

    const tabWindowColumns = [
      {
        header: 'Case details',
        align: 'left',
        valueName: 'caseDetails'
      },
      {
        header: 'Type(s)',
        align: 'left',
        valueName: 'type'
      },
      {
        header: 'Docket number',
        align: 'left',
        valueName: 'docketNumber'
      },
      {
        header: 'Location',
        align: 'left',
        valueName: 'location'
      },
      {
        header: 'Time',
        align: 'left',
        valueName: 'time'
      }
    ];

    const selectedHearingDay = this.props.selectedHearingDay;

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;

    return <div className="usa-width-three-fourths">
      <h1>
        {formatDateStr(selectedHearingDay.hearingDate)} {selectedHearingDay.roomInfo} ({availableSlots} slots remaining)
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableRows(this.props.selectedHearingDay.hearings)}
              summary="scheduled-hearings-table"
            />
          },
          {
            label: 'Assign Hearings',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableRows(this.props.veteransReadyForHearing)}
              summary="assign-hearings-table"
            />
          }
        ]}
      />
    </div>;
  };

  render() {
    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
      </Link>
      <RoSelectorDropdown
        regionalOffices={this.props.regionalOffices}
        onChange={this.props.onRegionalOfficeChange}
        value={this.props.selectedRegionalOffice}
      />
      {this.props.upcomingHearingDays && this.formatAvailableHearingDays()}
      {this.props.upcomingHearingDays &&
        this.props.veteransReadyForHearing &&
        this.props.selectedHearingDay &&
        this.veteransReadyForHearing()}
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  onRegionalOfficeChange: PropTypes.func,
  selectedRegionalOffice: PropTypes.object,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.object,
  veteransReadyForHearing: PropTypes.object
};
