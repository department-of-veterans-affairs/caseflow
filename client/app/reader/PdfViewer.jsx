import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import Modal from '../components/Modal';
import { closeAnnotationDeleteModal, deleteAnnotation, showPlaceAnnotationIcon,
  selectCurrentPdf } from '../reader/actions';
import { isUserEditingText, update } from '../reader/utils';
import { bindActionCreators } from 'redux';
import { getFilteredDocuments } from './selectors';
import * as Constants from '../reader/constants';
import { CATEGORIES, ACTION_NAMES, INTERACTION_TYPES } from '../reader/analytics';

export const getNextAnnotationIconPageCoords = (direction, placingAnnotationIconPageCoords, allPagesCoordsBounds) => {
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
    ...pageCoords
  } = update(placingAnnotationIconPageCoords, {
    [movementDimension]: {
      $apply: (coord) => coord + (moveAmountPx * movementDirection)
    }
  });

  const pageCoordsBounds = allPagesCoordsBounds[pageIndex];

  // This calculation is not quite right, because we are not using the scale
  // to correct ANNOTATION_ICON_SIDE_LENGTH. This leads to the outer edge of where
  // you're able to place the annotation with the keyboard looking progressively
  // weirder as you get further from zoom level 0. I am not going to fix this issue
  // now, because `scale` is stored in the state of `PdfUI`, and this PR is already
  // too massive. This can be a follow-up issue.
  return {
    x: _.clamp(pageCoords.x, 0, pageCoordsBounds.width - Constants.ANNOTATION_ICON_SIDE_LENGTH),
    y: _.clamp(pageCoords.y, 0, pageCoordsBounds.height - Constants.ANNOTATION_ICON_SIDE_LENGTH)
  };
};

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export class PdfViewer extends React.Component {
  // eslint-disable-next-line max-statements
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
      const { pageIndex, ...origCoords } = this.props.placingAnnotationIconPageCoords;
      const constrainedCoords = getNextAnnotationIconPageCoords(
        direction,
        this.props.placingAnnotationIconPageCoords,
        this.props.pageCoordsBounds
      );

      if (!_.isEqual(origCoords, constrainedCoords)) {
        this.props.showPlaceAnnotationIcon(pageIndex, constrainedCoords);
      }

      // If the user is placing an annotation, we do not also want
      // to be panning around on the page view with the arrow keys.
      event.preventDefault();

      return;
    }

    if (event.key === 'ArrowLeft' && !this.props.placedButUnsavedAnnotation) {
      window.analyticsEvent(
        CATEGORIES.VIEW_DOCUMENT_PAGE,
        ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
        INTERACTION_TYPES.KEYBOARD_SHORTCUT
      );
      this.props.showPdf(this.getPrevDocId())();
    }
    if (event.key === 'ArrowRight' && !this.props.placedButUnsavedAnnotation) {
      window.analyticsEvent(
        CATEGORIES.VIEW_DOCUMENT_PAGE,
        ACTION_NAMES.VIEW_NEXT_DOCUMENT,
        INTERACTION_TYPES.KEYBOARD_SHORTCUT
      );
      this.props.showPdf(this.getNextDocId())();
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

  getPrevDoc = () => _.get(this.props.documents, [this.selectedDocIndex() - 1])
  getNextDoc = () => _.get(this.props.documents, [this.selectedDocIndex() + 1])

  getPrevDocId = () => _.get(this.getPrevDoc(), 'id')
  getNextDocId = () => _.get(this.getNextDoc(), 'id')

  getPrefetchFiles = () => _.compact(_.map([this.getPrevDoc(), this.getNextDoc()], 'content_url'))

  showClaimsFolderNavigation = () => this.props.allDocuments.length > 1;

  shouldComponentUpdate(nextProps, nextState) {
    const getRenderProps = (props) => _.omit(props, 'pageCoordsBounds');

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
            prefetchFiles={this.getPrefetchFiles()}
            pdfWorker={this.props.pdfWorker}
            id="pdf"
            documentPathBase={this.props.documentPathBase}
            onPageClick={this.placeComment}
            onShowList={this.props.onShowList}
            prevDocId={this.getPrevDocId()}
            nextDocId={this.getNextDocId()}
            showPdf={this.props.showPdf}
            showClaimsFolderNavigation={this.showClaimsFolderNavigation()}
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
  ..._.pick(state, 'placingAnnotationIconPageCoords', 'pageCoordsBounds'),
  ..._.pick(state.ui, 'deleteAnnotationModalIsOpenFor', 'placedButUnsavedAnnotation'),
  ..._.pick(state.ui.pdf, 'scrollToComment', 'hidePdfSidebar', 'isPlacingAnnotation')
});
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    showPlaceAnnotationIcon,
    closeAnnotationDeleteModal,
    deleteAnnotation
  }, dispatch),

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
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};
