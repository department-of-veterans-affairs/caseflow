import React from 'react';
import PropTypes from 'prop-types';
import format from 'date-fns/format';
import { css } from 'glamor';

import { GreenCheckmarkIcon } from 'app/components/icons/GreenCheckmarkIcon';
import { grayLineTimelineStyling } from 'app/queue/components/TaskRows';

import { COLORS } from 'app/constants/AppConstants';
import { CASE_TIMELINE_APPELLANT_SUBSTITUTION_PROCESSED } from 'app/../COPY';

const timelineInfoStyling = css({
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
    textTransform: 'uppercase',
  },
});

export const SubstitutionProcessedTimelineEvent = ({ timelineEvent }) => {
  if (!timelineEvent.createdAt) {
    return null;
  }
  const processedDate = new Date(timelineEvent.createdAt);
  const formattedDate = format(processedDate, 'MM/dd/yyyy');

  return (
    <tr>
      <td className="taskContainerStyling taskTimeTimelineContainerStyling">
        <div>{formattedDate}</div>
      </td>
      <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
        <GreenCheckmarkIcon />
        <div {...grayLineTimelineStyling} />
      </td>
      <td className="taskContainerStyling taskInformationTimelineContainerStyling">
        {CASE_TIMELINE_APPELLANT_SUBSTITUTION_PROCESSED}
        <div {...timelineInfoStyling}>
          <div>
            <span>Completed by:</span>
            {timelineEvent.createdBy}
          </div>
          { timelineEvent.originalAppellantFullName &&
            <div>
              <span>Original appellant (veteran):</span>
              {timelineEvent.originalAppellantFullName}
            </div>
          }
          { timelineEvent.originalAppellantSubstituteFullName &&
            <div>
              <span>Original appellant (substitution):</span>
              {timelineEvent.originalAppellantSubstituteFullName}
            </div>
          }
          { timelineEvent.currentAppellantSubstituteFullName &&
            <div>
              <span>Current appellant (substitution):</span>
              {timelineEvent.currentAppellantSubstituteFullName}
            </div>
          }
          { timelineEvent.currentAppellantFullName &&
            <div>
              <span>Current appellant (veteran):</span>
              {timelineEvent.currentAppellantFullName}
            </div>
          }
        </div>
      </td>
    </tr>
  );
};
SubstitutionProcessedTimelineEvent.propTypes = {
  timelineEvent: PropTypes.shape({
    createdAt: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.instanceOf(Date),
    ]),
    createdBy: PropTypes.string,
    originalAppellantFullName: PropTypes.string,
    currentAppellantSubstituteFullName: PropTypes.string,
    originalAppellantSubstituteFullName: PropTypes.string,
    currentAppellantFullName: PropTypes.string
  }),
};
