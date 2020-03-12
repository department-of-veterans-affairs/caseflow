import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment';

import { HearingDocketTag, HearingAppellantName } from './AssignHearingsFields';
import { HearingTime } from '../HearingTime';
import {
  encodeQueryParams,
  getQueryParams,
} from '../../../util/QueryParamsUtil';
import { renderAppealType } from '../../../queue/utils';
import { tableNumberStyling } from './styles';
import LinkToAppeal from './LinkToAppeal';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG.json';
import QueueTable from '../../../queue/QueueTable';

export default class UpcomingHearingsTable extends React.PureComponent {

  componentDidMount = () => {
    this.updateQueryString();
  }

  updateQueryString = () => {
    const currentQueryParams = getQueryParams(window.location.search);

    // Overwrite the current tab name in the query string.
    currentQueryParams[QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM] = QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME;

    // This table doesn't use pagination, so the page param can be removed.
    delete currentQueryParams[QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM];

    window.history.replaceState('', '', encodeQueryParams(currentQueryParams));
  }

  getLinkToAppeal = (appealExternalId) => {
    const { selectedHearingDay, selectedRegionalOffice } = this.props;
    const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
    const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}`;

    return `/queue/appeals/${appealExternalId}/${qry}`;
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
        valueFunction: (row) => <HearingTime hearing={row} />
      }
    ];

    return columns;
  }

  render() {
    const { hearings, selectedHearingDay } = this.props;

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
