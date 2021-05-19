// React
import React from 'react';
import { css } from 'glamor';
// Libraries
import PropTypes from 'prop-types';
// Caseflow
import { COLORS } from 'app/constants/AppConstants';

export const InfoAlert = ({ timeString }) => {
  const alertContainerStyles = css({
    display: 'flex',
    alignItems: 'center'
  });

  const greyRectangleStyles = css({
    background: COLORS.GREY_LIGHT,
    width: '1rem',
    height: '4rem',
    display: 'inline-block',
    marginRight: '1.5rem'
  });
  const textDivStyles = css({
    display: 'inline-block',
    fontStyle: 'italic'
  });

  return (
    <div className="info-alert" {...alertContainerStyles}>
      <div {...greyRectangleStyles} />
      <div {...textDivStyles}>{`The hearing will start at ${timeString} Eastern Time`}</div>
    </div>
  );
};

InfoAlert.propTypes = {
  timeString: PropTypes.string
};
