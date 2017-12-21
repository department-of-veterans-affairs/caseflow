import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

import PdfUI from './PdfUI';
import PdfSidebar from './PdfSidebar';
import Modal from '../components/Modal';
import { fetchAppealDetails, showSearchBar
} from '../reader/PdfViewer/PdfViewerActions';
import { selectCurrentPdf } from '../reader/Documents/DocumentsActions';
import { stopPlacingAnnotation, showPlaceAnnotationIcon, deleteAnnotation, closeAnnotationDeleteModal
} from '../reader/AnnotationLayer/AnnotationActions';

import { isUserEditingText, shouldFetchAppeal } from './utils';
import { update } from '../util/ReducerUtil';
import { bindActionCreators } from 'redux';
import { getFilteredDocuments } from './selectors';
import * as Constants from './constants';
import { ROTATION_INCREMENTS } from './Documents/actionTypes';
import { CATEGORIES, ACTION_NAMES, INTERACTION_TYPES } from './analytics';

const NUMBER_OF_DIRECTIONS = 4;

// Given a direction, the current coordinates, an array of the div elements for each page,
// the file, and rotation of the document, this function calculates the next location of the comment.
// eslint-disable-next-line max-len
export const getNextAnnotationIconPageCoords = (direction, placingAnnotationIconPageCoords, pageDimensions, file, rotation = 0) => {
  // There are four valid rotations: 0, 90, 180, 270. We transform those values to 0, -1, -2, -3.
  // We then use that value to rotate the direction. I.E. Hitting up (value 0) on the
  // keyboard when rotated 90 degrees corresponds to moving left (value 3) on the document.
  const rotationIncrements = -(rotation / ROTATION_INCREMENTS) % NUMBER_OF_DIRECTIONS;
  const transformedDirection = Constants.MOVE_ANNOTATION_ICON_DIRECTION_ARRAY[
    (direction + rotationIncrements + NUMBER_OF_DIRECTIONS) % NUMBER_OF_DIRECTIONS];
  const moveAmountPx = 5;
  const movementDirection = _.includes(
    [Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP, Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT],
    transformedDirection
  ) ? -1 : 1;
  const movementDimension = _.includes(
    [Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP, Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN],
    transformedDirection
  ) ? 'y' : 'x';

  const {
    pageIndex,
    ...pageCoords
  } = update(placingAnnotationIconPageCoords, {
    [movementDimension]: {
      $apply: (coord) => coord + (moveAmountPx * movementDirection)
    }
  });

  const pageCoordsBounds = pageDimensions[`${file}-${pageIndex}`];

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

    if (this.props.isPlacingAnnotation && direction >= 0) {
      const { pageIndex, ...origCoords } = this.props.placingAnnotationIconPageCoords;
      const constrainedCoords = getNextAnnotationIconPageCoords(
        direction,
        this.props.placingAnnotationIconPageCoords,
        this.props.pageDimensions,
        this.selectedDoc().content_url,
        this.selectedDoc().rotation
      );

      if (!_.isEqual(origCoords, constrainedCoords)) {
        this.props.showPlaceAnnotationIcon(pageIndex, constrainedCoords);
      }

      // If the user is placing an annotation, we do not also want
      // to be panning around on the page view with the arrow keys.
      event.preventDefault();

      return;
    }

    if (event.key === 'ArrowLeft') {
      window.analyticsEvent(
        CATEGORIES.VIEW_DOCUMENT_PAGE,
        ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
        INTERACTION_TYPES.KEYBOARD_SHORTCUT
      );
      this.props.showPdf(this.getPrevDocId())();
      this.props.stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);
    }
    if (event.key === 'ArrowRight') {
      window.analyticsEvent(
        CATEGORIES.VIEW_DOCUMENT_PAGE,
        ACTION_NAMES.VIEW_NEXT_DOCUMENT,
        INTERACTION_TYPES.KEYBOARD_SHORTCUT
      );
      this.props.showPdf(this.getNextDocId())();
      this.props.stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);
    }
  }

  updateWindowTitle = () => {
    document.title = `${this.selectedDoc().type} | Document Viewer | Caseflow Reader`;
  }

  componentDidUpdate = () => {
    if (this.props.placedButUnsavedAnnotation) {
      let commentBox = document.getElementById('addComment');

      commentBox.focus();
    }
    this.updateWindowTitle();
  }

  componentDidMount() {
    this.props.handleSelectCurrentPdf(this.selectedDocId());
    window.addEventListener('keydown', this.keyListener);

    if (shouldFetchAppeal(this.props.appeal, this.props.match.params.vacolsId)) {
      this.props.fetchAppealDetails(this.props.match.params.vacolsId);
    }
    this.updateWindowTitle();
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
    const getRenderProps = (props) => _.omit(props, 'pageDimensions');

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
            prevDocId={this.getPrevDocId()}
            nextDocId={this.getNextDocId()}
            history={this.props.history}
            showPdf={this.props.showPdf}
            showClaimsFolderNavigation={this.showClaimsFolderNavigation()}
            featureToggles={this.props.featureToggles}
          />
          <PdfSidebar
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
  appeal: state.pdfViewer.loadedAppeal,
  ..._.pick(state.pdfViewer, 'hidePdfSidebar'),
  ..._.pick(state.annotationLayer, 'placingAnnotationIconPageCoords',
    'deleteAnnotationModalIsOpenFor', 'placedButUnsavedAnnotation', 'isPlacingAnnotation'),
  ..._.pick(state.pdf, 'scrollToComment', 'pageDimensions')
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    showPlaceAnnotationIcon,
    closeAnnotationDeleteModal,
    deleteAnnotation,
    stopPlacingAnnotation,
    fetchAppealDetails,
    showSearchBar
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
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool,
  showPdf: PropTypes.func
};
