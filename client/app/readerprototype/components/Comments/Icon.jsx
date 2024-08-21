import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';
import CommentIcon from '../../../reader/CommentIcon';
import { useSelector } from 'react-redux';
import { annotationPlacement } from '../../selectors';

// The comment icon (speech bubble) works best when the pointy part of the bubble
// lines up with the word that the user is trying to comment on.
// As the parent document is rotated, the icons need to be rotated in the opposite direction
// and offset to keep them in the original orientation and 'aimed' correctly.
const OFFSETS = {
  0: {
    x: -10,
    y: -30,
  },
  [-90]: {
    x: -30,
    y: -25,
  },
  [-180]: {
    x: -25,
    y: -5,
  },
  [-270]: {
    x: -5,
    y: -10,
  },
  [-360]: {
    x: -10,
    y: -30,
  },
};
const Icon = (props) => {
  const { position, rotation, comment } = props;

  const { selectedAnnotationId } = useSelector(annotationPlacement);
  const iconRef = useRef(null);

  useEffect(() => {
    if (selectedAnnotationId === comment.id && iconRef.current) {
      iconRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [selectedAnnotationId, iconRef.current, comment.id]);

  return (
    <CommentIcon
      innerRef={(el) => (iconRef.current = el)}
      {...props}
      position={{
        x: position.x + OFFSETS[rotation].x,
        y: position.y + OFFSETS[rotation].y,
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
