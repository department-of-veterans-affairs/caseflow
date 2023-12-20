// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { isEmpty } from 'lodash';

// Internal Dependencies
import { File } from 'components/reader/DocumentViewer/PDF/File';
import { pdfStyles, fileContainerStyles } from 'styles/reader/Document/PDF';
import StatusMessage from 'app/components/StatusMessage';
import { keyHandler, formatCommentQuery, focusComment } from 'utils/reader';

/**
 * PDF Container for the Document view
 * @param {Object} props -- Contains PDF file and file list and functions to change
 */
export const Pdf = ({ doc, clickPage, ...props }) => {
  useEffect(() => {
    // Parse the annotation ID
    const commentId = formatCommentQuery();

    // Determine if there is a comment in the URL
    const commentQuery = props.comments.length && commentId;

    // Instantiate the comment object
    const selectedComment = commentQuery ?
      props.comments.filter((item) => item.id === commentId)[0] :
      props.selectedComment;

    // Handle the `JumpToComment` feature
    if (!isEmpty(selectedComment)) {
      // Scroll the DOM to the selected comment
      focusComment(selectedComment);

      // Update the Page number so that `react-virtualized` resizes the window
      props.setPageNumber(selectedComment.page - 1);

      // Ensure the comment is selected in the store
      props.selectComment(selectedComment);
    }

    // Create the Keyboard Listener
    const listener = (event) => keyHandler(event, props);

    // Attach the key listener
    document.addEventListener('keydown', listener);

    // Remove the key listener when the component is unmounted
    return () => document.removeEventListener('keydown', listener);
  }, [
    props.currentPageIndex,
    props.currentDocument?.id,
    props.search,
    props.selectedComment,
    props.hideSearchBar,
    props.addingComment,
    props.droppedComment,
    props.editingComment,
    props.editingTag
  ]);

  return (
    <div className="cf-pdf-scroll-view">
      <div id={doc.content_url} style={fileContainerStyles} onClick={clickPage}>
        {doc.loadError ? (
          <div>
            <div style={pdfStyles} >
              <StatusMessage title="Unable to load document" type="warning">
              Caseflow is experiencing technical difficulties and cannot load <strong>{doc.type}</strong>.
                <br />
              You can try <a href={`${doc.content_url}?type=${doc.type}&download=true`}>downloading the document</a>
              or try again later.
              </StatusMessage>
            </div>
          </div>
        ) : (
          <File
            key={`${doc.content_url}`}
            file={doc.content_url}
            documentType={doc.type}
            currentDocument={doc}
            {...props}
          />
        )}
      </div>
    </div>
  );
};

Pdf.propTypes = {
  doc: PropTypes.object,
  currentDocument: PropTypes.object,
  currentPageIndex: PropTypes.number,
  selectedComment: PropTypes.object,
  documentType: PropTypes.string,
  loadError: PropTypes.string,
  clickPage: PropTypes.func,
  selectComment: PropTypes.func,
  setPageNumber: PropTypes.func,
  search: PropTypes.object,
  hideSearchBar: PropTypes.bool,
  addingComment: PropTypes.bool,
  droppedComment: PropTypes.object,
  editingComment: PropTypes.bool,
  editingTag: PropTypes.bool,
  comments: PropTypes.array,
};
