import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import Comment from '../../../reader/Comment';
import { useSelector } from 'react-redux';
import { annotationPlacement } from '../../selectors';

const Item = (props) => {
  const itemRef = useRef(null);
  const { selectedAnnotationId } = useSelector(annotationPlacement);

  useEffect(() => {
    if (selectedAnnotationId === props.id && itemRef.current) {
      itemRef.current.scrollIntoView();
    }
  }, [selectedAnnotationId, itemRef.current, props.id]);

  return (
    <Comment
      {...props}
      innerRef={(el) => {
        if (props.id === selectedAnnotationId) {
          itemRef.current = el;
        }
      }}
    />
  );
};

Item.propTypes = {
  children: PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  openAnnotationDeleteModal: PropTypes.func,
  openAnnotationShareModal: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number,
  horizontalLayout: PropTypes.bool,
  innerRef: PropTypes.any,
};

export default Item;
