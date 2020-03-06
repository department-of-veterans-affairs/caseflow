import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';
import PropTypes from 'prop-types';

import { renderAppealType } from '../../../queue/utils';
import { HearingTime, HearingDocketTag, HearingAppellantName } from './AssignHearingsFields';
import { NoUpcomingHearingDayMessage } from './Messages';
import QueueTable from '../../../queue/QueueTable';
import { tableNumberStyling } from './styles';

export default class UpcomingHearingsTable extends React.PureComponent {

  isCentralOffice = () => {
    return this.props.selectedRegionalOffice === 'C';
  }

  getLinkToAppeal = (appealExternalId) => {
    const { selectedHearingDay, selectedRegionalOffice } = this.props;
    const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
    const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}`;

    return `/queue/appeals/${appealExternalId}/${qry}`;
  }

  getColumns = () => {
    const columns = [
      {
        header: '',
        align: 'left',
        // Since this column isn't tied to anything in the input row, _value will
        // always be undefined.
        valueFunction: (_value, rowId) => <span>{rowId + 1}.</span>
      },
      {
        header: 'Case Details',
        align: 'left',
        valueFunction: (row) => (
          <Link
            name={row.appealExternalId}
            href={this.getLinkToAppeal(row.appealExternalId)}>
            <HearingAppellantName hearing={row} />
          </Link>
        )
      },
      {
        header: 'Type(s)',
        align: 'left',
        valueFunction: (row) => renderAppealType({
          caseType: row.appealType,
          isAdvancedOnDocket: row.aod
        })
      },
      {
        header: 'Docket Number',
        align: 'left',
        valueFunction: (row) => <HearingDocketTag hearing={row} />
      },
      {
        name: 'Hearing Location',
        header: 'Hearing Location',
        align: 'left',
        columnName: 'readableLocation',
        valueName: 'readableLocation',
        label: 'Filter by location',
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      },
      {
        header: 'Time',
        align: 'left',
        valueFunction: (row) => (
          <HearingTime hearing={row} isCentralOffice={this.isCentralOffice()} />
        )
      }
    ];

    return columns;
  }

  render() {
    const { hearings, selectedHearingDay } = this.props;

    if (_.isNil(selectedHearingDay)) {
      return <NoUpcomingHearingDayMessage />;
    }

    return (
      <div>
        <Link to={`/schedule/docket/${selectedHearingDay.id}`}>
          {`View the Daily Docket for ${moment(selectedHearingDay.scheduledFor).format('M/DD/YYYY')}` }
        </Link>
        <QueueTable
          columns={this.getColumns()}
          rowObjects={Object.values(hearings)}
          slowReRendersAreOk
          summary="upcoming-hearings"
          bodyStyling={tableNumberStyling}
        />
      </div>
    );
  }
}

UpcomingHearingsTable.propTypes = {
  hearings: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string
  }),
  selectedRegionalOffice: PropTypes.string
};
