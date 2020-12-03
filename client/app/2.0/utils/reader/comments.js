// External Dependencies
import { sortBy } from 'lodash';

// Local Dependencies
import { escapeRegExp } from 'utils/reader/format';
import { COMMENT_SCROLL_FROM_THE_TOP } from 'app/2.0/store/constants/reader';

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

export const focusComment = (comment) => {
  // Set the comment component
  const commentComponent = document.getElementById(`comment-${comment.id}`);

  // Set the Parent component
  const parent = document.getElementById('cf-sidebar-accordion');

  // Focus the comment if found
  if (commentComponent) {
    // Get the position from the top for the comment component
    const commentTop = commentComponent.getBoundingClientRect().top;

    // Get the position from the top for the parent component
    const parentTop = parent.getBoundingClientRect().top;

    // Update the Scroll position according to the parent and base scroll from the top
    parent.scrollTop = parent.scrollTop + commentTop - parentTop - COMMENT_SCROLL_FROM_THE_TOP;
  }
};
