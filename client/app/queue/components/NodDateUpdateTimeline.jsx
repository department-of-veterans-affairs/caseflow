import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import moment from 'moment-timezone';
import { formatDateStr } from '../../util/DateUtil';
import { changeReasons } from './EditNodDateModal';

import COPY from 'app/../COPY';
import { GreenCheckmark } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { grayLineTimelineStyling } from './TaskRows';
import { useSelector } from 'react-redux';

const nodDateUpdateTimelineTimeStyling = css({
  color: COLORS.GREY_MEDIUM,
  fontSize: '15px'
});

const nodDateUpdateTimelineInfoStyling = css({
  display: 'flex',
  flexWrap: 'wrap',
  '& *': {
    whiteSpace: 'nowrap',
    marginRight: '1rem',
  },
  '& span': {
    color: COLORS.GREY_MEDIUM,
    fontSize: '1.5rem',
    marginRight: '0.5rem',
    textTransform: 'uppercase'
  }
});

export const NodDateUpdateTimeline = (props) => {
  const { timelineEvent: nodDateUpdate, timeline } = props;
  const changeReason = changeReasons.find((reason) => reason.value === nodDateUpdate.changeReason).label;
  const viewNodDateUpdates = useSelector((state) => state.ui.featureToggles.view_nod_date_updates);

  return <React.Fragment>
    {viewNodDateUpdates && timeline && <tr>
      <td className="taskContainerStyling taskTimeTimelineContainerStyling">
        <div>{ moment(nodDateUpdate.updatedAt).format('MM/DD/YYYY') }</div>
        <div {...nodDateUpdateTimelineTimeStyling}>
          { moment(nodDateUpdate.updatedAt).tz('America/New_York').
            format('HH:mm:ss') } EST
        </div>
      </td>
      <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
        <GreenCheckmark />
        <div {...grayLineTimelineStyling} />
      </td>
      <td className="taskContainerStyling taskInformationTimelineContainerStyling">
        { COPY.CASE_TIMELINE_NOD_DATE_UPDATE }
        <div {...nodDateUpdateTimelineInfoStyling}>
          <div><span>Edited:</span>{nodDateUpdate.userFirstName.split('')[0]}. {nodDateUpdate.userLastName}</div>
          <div><span>Old Nod:</span>{formatDateStr(nodDateUpdate.oldDate)}</div>
          <div><span>New Nod:</span>{formatDateStr(nodDateUpdate.newDate)}</div>
          <div><span>Reason:</span>{changeReason}</div>
        </div>
      </td>
    </tr>
    }
  </React.Fragment>;
};

NodDateUpdateTimeline.propTypes = {
  timelineEvent: PropTypes.shape({
    changeReason: PropTypes.string.isRequired,
    updatedAt: PropTypes.string.isRequired,
    newDate: PropTypes.string.isRequired,
    oldDate: PropTypes.string.isRequired,
    userFirstName: PropTypes.string.isRequired,
    userLastName: PropTypes.string.isRequired
  }).isRequired,
  timeline: PropTypes.bool.isRequired
};
