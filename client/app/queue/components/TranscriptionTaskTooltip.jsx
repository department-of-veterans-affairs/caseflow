import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import COPY from 'app/../COPY';
import Tooltip from '../../components/Tooltip';

const instructionStyling = css({
  maxWidth: '300px',
  textAlign: 'left'
});

// Creates a tool tip that displays task instructions
const TranscriptionTaskTooltip = (props) => {
  const { instructions, taskId, children } = props;
  const instructionText = instructions.trim() ? instructions : COPY.CASE_LIST_TABLE_TASK_NO_INSTRUCTIONS_TOOLTIP;

  const tooltipText = (
    <div style={{ whiteSpace: 'pre-line' }}>
      <div {...instructionStyling}>{instructionText}</div>
    </div>
  );

  return <Tooltip id={`task-${taskId}`} text={tooltipText} position="bottom" >{children}</Tooltip>;
};

TranscriptionTaskTooltip.propTypes = {
  instructions: PropTypes.string,
  taskId: PropTypes.string,
  children: PropTypes.node
};

export default TranscriptionTaskTooltip;
