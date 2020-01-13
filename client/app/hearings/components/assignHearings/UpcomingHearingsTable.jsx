import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { HearingTime, HearingDocketTag, HearingAppellantName } from './AssignHearingsFields';
import { NoUpcomingHearingDayMessage } from './Messages';
import { renderAppealType } from '../../../queue/utils';
import { tableNumberStyling } from './styles';
import LinkToAppeal from './LinkToAppeal';
import QueueTable from '../../../queue/QueueTable';

export default class UpcomingHearingsTable extends React.PureComponent {

  isCentralOffice = () => {
    return this.props.selectedRegionalOffice === 'C';
  }

  getColumns = () => {
    const { selectedHearingDay, selectedRegionalOffice } = this.props;
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
          <LinkToAppeal
            appealExternalId={row.appealExternalId}
            hearingDay={selectedHearingDay}
            regionalOffice={selectedRegionalOffice}
          >
            <HearingAppellantName hearing={row} />
          </LinkToAppeal>
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
