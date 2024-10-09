import PropTypes from 'prop-types';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  cancelEditAnnotation,
  requestEditAnnotation,
  startEditAnnotation,
  updateAnnotationContent,
  updateAnnotationRelevantDate,
} from '../../../reader/AnnotationLayer/AnnotationActions';
import EditComment from '../../../reader/EditComment';
import { editingAnnotationsSelector } from '../../selectors';
import Item from './Item';

const List = (props) => {
  const { annotations, onSelect, selectedAnnotationId } = props;

  const dispatch = useDispatch();
  const editingAnnotations = useSelector(editingAnnotationsSelector);

  return annotations.map((annotation, index) => {
    const editedAnnotation = editingAnnotations.find((edited) => edited?.uuid === annotation?.uuid);

    return editedAnnotation ? (
      <EditComment
        key={index}
        comment={editedAnnotation}
        value={editedAnnotation.comment}
        onCancelCommentEdit={(id) => dispatch(cancelEditAnnotation(id))}
        onChange={(event, id) => dispatch(updateAnnotationContent(event, id))}
        onChangeDate={(relevantDate) => dispatch(updateAnnotationRelevantDate(relevantDate, editedAnnotation.uuid))}
        onSaveCommentEdit={(comment) => dispatch(requestEditAnnotation(comment))}
        disableOnEmpty
      />
    ) : (
      <Item
        {...annotation}
        key={index}
        date={annotation.relevant_date}
        selected={annotation.id === selectedAnnotationId}
        onClick={onSelect}
        onEditComment={(id) => dispatch(startEditAnnotation(id))}
      >
        {annotation.comment}
      </Item>
    );
  });
};

List.propTypes = {
  annotations: PropTypes.object,
  onSelect: PropTypes.func,
  selectedAnnotationId: PropTypes.number,
};

export default List;
