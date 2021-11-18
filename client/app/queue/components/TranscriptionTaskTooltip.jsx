import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Tooltip from '../../components/Tooltip';

const instructionStyling = css({
  maxWidth: '140px',
  textAlign: 'left'
});

// Creates a tool tip that displays who assigned a transcription task, as well as any task instructions
const TranscriptionTaskTooltip = (props) => {
  const { assignedBy, instructions, uniqueId, children } = props;
  const displayName = `${assignedBy.firstName} ${assignedBy.lastName}`
  const instructionText = instructions.length > 0 ? instructions : 'No instructions.'

  const tooltipText = (
    <div>
      {displayName.trim() ? <div><strong>Assigned By: </strong> {displayName}</div> : ''}
      {<div {...instructionStyling}>{instructionText}</div>}
    </div>
  );

  return <Tooltip id={`task-${uniqueId}`} text={tooltipText} position="bottom" >{children}</Tooltip>;
};

TranscriptionTaskTooltip.propTypes = {
  assignedBy: PropTypes.object,
  instructions: PropTypes.string,
  uniqueId: PropTypes.string,
  children: PropTypes.node
};

export default TranscriptionTaskTooltip;
