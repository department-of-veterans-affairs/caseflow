import PropTypes from 'prop-types';
import React from 'react';

import { useDispatch, useSelector } from 'react-redux';
import Button from '../../../components/Button';
import { PlusIcon } from '../../../components/icons/PlusIcon';
import { INTERACTION_TYPES } from '../../../reader/analytics';
import {
  createAnnotation,
  selectAnnotation,
  startPlacingAnnotation,
  stopPlacingAnnotation,
  updateNewAnnotationContent,
  updateNewAnnotationRelevantDate,
} from '../../../reader/AnnotationLayer/AnnotationActions';
import CannotSaveAlert from '../../../reader/CannotSaveAlert';
import EditComment from '../../../reader/EditComment';
import { onScrollToComment } from '../../../reader/Pdf/PdfActions';
import { annotationPlacement, annotationsForDocumentId, commentErrorSelector } from '../../selectors';
import List from './List';

const Comments = ({ documentId }) => {
  const annotations = useSelector((state) => annotationsForDocumentId(state, documentId));
  const { placedButUnsavedAnnotation, selectedAnnotationId } = useSelector(annotationPlacement);
  const errors = useSelector(commentErrorSelector);

  const dispatch = useDispatch();

  const handleAddClick = (event) => {
    dispatch(startPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
    event.stopPropagation();
  };
  const handleStopPlacing = () => dispatch(stopPlacingAnnotation('from-canceling-new-annotation'));
  const handleSelect = (uuid) => {
    dispatch(selectAnnotation(uuid));
    dispatch(onScrollToComment(annotations.find((annotation) => annotation?.uuid === uuid)));
  };

  return (
    <div>
      <span className="cf-right-side cf-add-comment-button">
        <Button name="AddComment" onClick={handleAddClick}>
          <span>
            <PlusIcon size={12} /> &nbsp; Add a comment
          </span>
        </Button>
      </span>
      <div style={{ clear: 'both' }} />
      <div className="cf-comment-wrapper">
        {errors?.visible && <CannotSaveAlert message={errors?.message} />}
        <div className="cf-pdf-comment-list">
          {placedButUnsavedAnnotation && (
            <EditComment
              comment={placedButUnsavedAnnotation}
              id="addComment"
              onChange={(event) => dispatch(updateNewAnnotationContent(event))}
              onChangeDate={(event) => dispatch(updateNewAnnotationRelevantDate(event))}
              onCancelCommentEdit={handleStopPlacing}
              onSaveCommentEdit={(annotation) => dispatch(createAnnotation(annotation))}
              disableOnEmpty
            />
          )}
          <List
            annotations={annotations.concat().sort((firstPage, secondPage) => firstPage.page - secondPage.page)}
            onSelect={handleSelect}
            selectedAnnotationId={selectedAnnotationId}
          />
        </div>
      </div>
    </div>
  );
};

Comments.propTypes = {
  documentId: PropTypes.number,
};

export default Comments;
