import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';
import CommentIcon from '../../../reader/CommentIcon';
import { useSelector } from 'react-redux';
import { annotationPlacement } from '../../selectors';

const Icon = (props) => {
  const { position, rotation, comment } = props;

  const { selectedAnnotationId } = useSelector(annotationPlacement);
  const iconRef = useRef(null);

  useEffect(() => {
    if (selectedAnnotationId === comment.id && iconRef.current) {
      iconRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [selectedAnnotationId, iconRef.current, comment.id]);

  let xDiff = -10;
  let yDiff = -30;

  if (rotation === -90) {
    xDiff = -30;
    yDiff = -25;
  }
  if (rotation === -180) {
    xDiff = -25;
    yDiff = -5;
  }
  if (rotation === -270) {
    xDiff = -5;
    yDiff = -10;
  }

  return (
    <CommentIcon
      innerRef={(el) => (iconRef.current = el)}
      {...props}
      position={{
        x: position.x + xDiff,
        y: position.y + yDiff,
      }}
    />
  );
};

Icon.propTypes = {
  position: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number,
  }),
  rotation: PropTypes.number,
  comment: PropTypes.object,
};

export default Icon;
