// External Dependencies
import { sortBy } from 'lodash';

// Local Dependencies
import { escapeRegExp } from './format';

/**
 * Helper Method to Calculate the Comment Rows
 * @param {array} documents -- The list of documents for the selected appeal
 * @param {array} annotationsPerDocument -- The list of comments for each document
 * @param {string} searchQuery -- The Query being used to filter
 * @returns {array} -- The list of comment rows for the table
 */
export const commentRows = (documents, annotationsPerDocument, searchQuery = '') => {
  // Group the Annotations
  const groupedAnnotations = annotationsPerDocument.map((notes) =>
    notes.map((note) => {
      // eslint-disable-next-line camelcase
      const { type, serialized_receipt_date } = documents.filter((doc) => doc.id === note.documentId)[0];

      return {
        ...note,
        docType: type,
        serialized_receipt_date
      };
    })
  ).
    filter((note) => {
      if (!searchQuery) {
        return true;
      }

      const query = new RegExp(escapeRegExp(searchQuery), 'i');

      return note.comment.match(query) || note.docType.match(query);
    }).
    groupBy((note) => (note.relevant_date ? 'relevant_date' : 'serialized_receipt_date')).
    value();

  // groupBy returns { relevant_date: [notes w/relevant_date], serialized_receipt_date: [notes w/out] }
  return sortBy(groupedAnnotations.relevant_date, 'relevant_date').concat(
    sortBy(groupedAnnotations.serialized_receipt_date, 'serialized_receipt_date')
  );
};

/**
 * Method to scroll the DOM to focus the comment details
 * @param {Object} comment -- The comment to focus
 */
export const focusComment = (comment) => {
  // Set the comment component
  const commentComponent = document.getElementById(`comment-${comment.id}`);
  const commentIcon = document.getElementById(`commentIcon-container-${comment.id}`);

  // Focus the comment if found
  if (commentComponent) {
    // Scroll the comment into view
    commentComponent.scrollIntoView();
  }

  if (commentIcon) {
    // Scroll the comment into view
    commentIcon.scrollIntoView();
  }
};
