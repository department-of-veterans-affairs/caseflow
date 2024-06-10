import _ from 'lodash';
import { CATEGORIES } from './readerConstants';

export const isValidWholeNumber = (number) => {
  return !isNaN(number) && number % 1 === 0;
};

export const validatePageNumber = (pageNumber, totalPages) => {
  const RADIX = 10;
  let pageNum = parseInt(pageNumber, RADIX);

  if (!pageNum || !isValidWholeNumber(pageNum) ||
    (pageNum < 1 || pageNum > totalPages)) {
    return false;
  }

  return true;
};

export const selectedDocIndex = (props) => {
  const selectedDocId = Number(props.match.params.docId);

  return _.findIndex(props.allDocuments, { id: selectedDocId });
};

export const selectedDoc = (props) => (
  props.allDocuments[selectedDocIndex(props)]
);

const getPrevDoc = (props) => _.get(props.allDocuments, [selectedDocIndex(props) - 1]);
const getNextDoc = (props) => _.get(props.allDocuments, [selectedDocIndex(props) + 1]);

export const getPrevDocId = (props) => _.get(getPrevDoc(props), 'id');
export const getNextDocId = (props) => _.get(getNextDoc(props), 'id');

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
  case '0deg':
    updatedRotateDeg = '90deg';
    break;
  case '90deg':
    updatedRotateDeg = '180deg';
    break;
  case '180deg':
    updatedRotateDeg = '270deg';
    break;
  case '270deg':
    updatedRotateDeg = '360deg';
    break;
  case '360deg':
    updatedRotateDeg = '90deg';
    break;
  default:
    updatedRotateDeg = '0deg';
  }

  return updatedRotateDeg;
};
