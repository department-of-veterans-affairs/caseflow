import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import { documentPath } from './DecisionReviewer';
import Modal from '../components/Modal';
import { closeAnnotationDeleteModal, deleteAnnotation, showPlaceAnnotationIcon,
  handleSelectCommentIcon, selectCurrentPdf } from '../reader/actions';
import { isUserEditingText, update } from '../reader/utils';
import { bindActionCreators } from 'redux';
import { getFilteredDocuments } from './selectors';
import * as Constants from '../reader/constants';

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export class PdfViewer extends React.Component {
  keyListener = (event) => {
    if (isUserEditingText()) {
      return;
    }

    const direction = {
      ArrowLeft: Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT,
      ArrowRight: Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
      ArrowUp: Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
      ArrowDown: Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN
    }[event.key];

    if (this.props.isPlacingAnnotation && direction) {
      const moveAmountPx = 5;
      const movementDirection = _.includes(
        [Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP, Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT],
        direction
      ) ? -1 : 1;
      const movementDimension = _.includes(
        [Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP, Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN],
        direction
      ) ? 'y' : 'x';

      const {
        pageIndex,
        ...scaledPageCoords
      } = update(this.props.placingAnnotationIconScaledPageCoords, {
        [movementDimension]: {
          $apply: (coord) => coord + (moveAmountPx * movementDirection)
        }
      });

      const scaledPageCoordsBounds = this.props.scaledPageCoordsBounds[pageIndex];

      const constrainedCoords = {
        x: _.clamp(scaledPageCoords.x, 0, scaledPageCoordsBounds.right - Constants.ANNOTATION_ICON_SIDE_LENGTH),
        y: _.clamp(scaledPageCoords.y, 0, scaledPageCoordsBounds.bottom - Constants.ANNOTATION_ICON_SIDE_LENGTH),
      };

      this.props.showPlaceAnnotationIcon(pageIndex, constrainedCoords);

      return;
    }

    if (event.key === 'ArrowLeft') {
      this.props.showPdf(this.prevDocId())();
    }
    if (event.key === 'ArrowRight') {
      this.props.showPdf(this.nextDocId())();
    }
  }

  componentDidUpdate = () => {
    if (this.props.placedButUnsavedAnnotation) {
      let commentBox = document.getElementById('addComment');

      commentBox.focus();
    }
  }

  componentDidMount() {
    this.props.handleSelectCurrentPdf(this.selectedDocId());
    window.addEventListener('keydown', this.keyListener);
  }

  componentWillUnmount = () => {
    window.removeEventListener('keydown', this.keyListener);
  }

  componentWillReceiveProps = (nextProps) => {
    const nextDocId = Number(nextProps.match.params.docId);

    if (nextDocId !== this.selectedDocId()) {
      this.props.handleSelectCurrentPdf(nextDocId);
    }
  }

  selectedDocIndex = () => (
    _.findIndex(this.props.documents, { id: this.selectedDocId() })
  )

  selectedDoc = () => (
    this.props.documents[this.selectedDocIndex()]
  )

  selectedDocId = () => Number(this.props.match.params.docId)

  prevDocId = () => _.get(this.props.documents, [this.selectedDocIndex() - 1, 'id'])
  nextDocId = () => _.get(this.props.documents, [this.selectedDocIndex() + 1, 'id'])

  getPrefetchFiles = () => _.compact([
    this.prevDocId(),
    this.nextDocId()
  ]).map(documentPath)

  showDocumentsListNavigation = () => this.props.allDocuments.length > 1;

  shouldComponentUpdate(nextProps, nextState) {
    const getRenderProps = (props) => _.omit(props, 'scaledPageCoordsBounds');

    return !(_.isEqual(this.state, nextState) && _.isEqual(getRenderProps(this.props), getRenderProps(nextProps)));
  }

  render() {
    const doc = this.selectedDoc();

    // If we don't have a currently selected document, we
    // shouldn't render anything. On the next tick we dispatch
    // the action to redux that populates the documents and then we
    // render
    // TODO(jd): We should refactor and potentially create the store
    // with the documents already added
    if (!doc) {
      return null;
    }

    return (
      <div>
        <div className="cf-pdf-page-container">
          <PdfUI
            doc={doc}
            file={documentPath(this.selectedDocId())}
            prefetchFiles={this.getPrefetchFiles()}
            pdfWorker={this.props.pdfWorker}
            id="pdf"
            documentPathBase={this.props.documentPathBase}
            onPageClick={this.placeComment}
            onShowList={this.props.onShowList}
            prevDocId={this.prevDocId()}
            nextDocId={this.nextDocId()}
            showPdf={this.props.showPdf}
            showDocumentsListNavigation={this.showDocumentsListNavigation()}
            onViewPortCreated={this.onViewPortCreated}
            onViewPortsCleared={this.onViewPortsCleared}
          />
          <PdfSidebar
            addNewTag={this.props.addNewTag}
            removeTag={this.props.removeTag}
            doc={doc}
            onJumpToComment={this.props.onJumpToComment}
          />
        </div>
        {this.props.deleteAnnotationModalIsOpenFor && <Modal
          buttons={[
            { classNames: ['cf-modal-link', 'cf-btn-link'],
              name: 'Cancel',
              onClick: this.props.closeAnnotationDeleteModal
            },
            { classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Confirm delete',
              onClick: () => this.props.deleteAnnotation(
                this.props.match.params.docId,
                this.props.deleteAnnotationModalIsOpenFor
              )
            }
          ]}
          closeHandler={this.props.closeAnnotationDeleteModal}
          title="Delete Comment">
          Are you sure you want to delete this comment?
        </Modal>}
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  documents: getFilteredDocuments(state),
  ..._.pick(state, 'placingAnnotationIconScaledPageCoords', 'scaledPageCoordsBounds'),
  ..._.pick(state.ui, 'deleteAnnotationModalIsOpenFor', 'placedButUnsavedAnnotation'),
  ..._.pick(state.ui.pdf, 'scrollToComment', 'hidePdfSidebar', 'isPlacingAnnotation')
});
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    showPlaceAnnotationIcon,
    closeAnnotationDeleteModal,
    deleteAnnotation
  }, dispatch),

  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment)),
  handleSelectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfViewer);

PdfViewer.propTypes = {
  doc: PropTypes.object,
  pdfWorker: PropTypes.string,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number
  }),
  deleteAnnotationModalIsOpenFor: PropTypes.number,
  onScrollToComment: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};
