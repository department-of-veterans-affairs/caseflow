import React from 'react';
import PropTypes from 'prop-types';

import { GreenCheckmark } from 'app/components/RenderFunctions';
import { grayLineTimelineStyling } from 'app/queue/components/TaskRows';
import format from 'date-fns/format';

import { CASE_TIMELINE_APPELLANT_SUBSTITUTION } from 'app/../COPY';

export const SubstituteAppellantTimelineEvent = ({ timelineEvent }) => {
  if (!timelineEvent.createdAt) {
    return null;
  }
  const substitutionDate = new Date(timelineEvent.createdAt);
  const formattedSubstutionDate = format(substitutionDate, 'MM/dd/yyyy');

  return (
    <tr>
      <td className="taskContainerStyling taskTimeTimelineContainerStyling">
        <div>{formattedSubstutionDate}</div>
      </td>
      <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
        <GreenCheckmark />
        <div {...grayLineTimelineStyling} />
      </td>
      <td className="taskContainerStyling taskInformationTimelineContainerStyling">
        {CASE_TIMELINE_APPELLANT_SUBSTITUTION}
      </td>
    </tr>
  );
};
SubstituteAppellantTimelineEvent.propTypes = {
  timelineEvent: PropTypes.shape({
    createdAt: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.instanceOf(Date),
    ]),
  }),
};
