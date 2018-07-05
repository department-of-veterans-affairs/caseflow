import React from 'react';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Table from '../../components/Table';
import {formatDate} from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';

export default class ListSchedule extends React.Component {

  render() {
    const {
      hearingSchedule
    } = this.props;

    const hearingScheduleColumns = [
      {
        header: 'Date',
        align: 'left',
        valueName: 'hearingDate'
      },
      {
        header: 'Type',
        align: 'left',
        valueName: 'hearingType'
      },
      {
        header: 'Regional Office',
        align: 'left',
        valueName: 'regionalOffice'
      },
      {
        header: 'Room',
        align: 'left',
        valueName: 'room'
      },
      {
        header: 'VLJ',
        align: 'left',
        valueName: 'vlj'
      }
    ];

    const hearingScheduleRows = _.map(hearingSchedule, (hearingDay) => ({
        hearingDate: `${formatDate(hearingDay.hearingDate)}`,
        hearingType: hearingDay.hearingType,
        regionalOffice: hearingDay.folderNr,
        room: hearingDay.roomInfo,
        vlj: hearingDay.judgeId
      }
    ));

    return <AppSegment filledBackground>
      <Table
        columns={hearingScheduleColumns}
        rowObjects={hearingScheduleRows}
        summary="hearing-schedule"
      />
    </AppSegment>;
  }
}

ListSchedule.propTypes = {
  hearingSchedule: PropTypes.shape({
    hearingDate: PropTypes.string,
    hearingType: PropTypes.string,
    folderNr: PropTypes.string,
    roomInfo: PropTypes.string,
    judgeId: PropTypes.string,
    updatedOn: PropTypes.string,
    updatedBy: PropTypes.string
  })
};
