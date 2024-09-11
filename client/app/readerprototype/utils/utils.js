import _ from 'lodash';
import { CATEGORIES, ROTATION_DEGREES } from './constants';

export const selectedDocIndex = (props) => {
  const selectedDocId = Number(props.match.params.docId);

  return _.findIndex(props.allDocuments, { id: selectedDocId });
};

export const selectedDoc = (props) => props.allDocuments[selectedDocIndex(props)];

export const openDownloadLink = (doc) => {
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');
  window.open(`${doc.content_url}?type=${doc.type}&download=true`);
};

export const handleClickDocumentTypeLink = () => {
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'document-type-link');
};

export const getRotationDeg = (rotateDeg) => {
  let updatedRotateDeg;

  switch (rotateDeg) {
    case ROTATION_DEGREES.ZERO:
      updatedRotateDeg = ROTATION_DEGREES.NINETY;
      break;
    case ROTATION_DEGREES.NINETY:
      updatedRotateDeg = ROTATION_DEGREES.ONE_EIGHTY;
      break;
    case ROTATION_DEGREES.ONE_EIGHTY:
      updatedRotateDeg = ROTATION_DEGREES.TWO_SEVENTY;
      break;
    case ROTATION_DEGREES.TWO_SEVENTY:
      updatedRotateDeg = ROTATION_DEGREES.THREE_SIXTY;
      break;
    case ROTATION_DEGREES.THREE_SIXTY:
      updatedRotateDeg = ROTATION_DEGREES.NINETY;
      break;
    default:
      updatedRotateDeg = ROTATION_DEGREES.ZERO;
  }

  return updatedRotateDeg;
};
