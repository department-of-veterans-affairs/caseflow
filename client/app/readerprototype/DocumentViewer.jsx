import PropTypes from 'prop-types';
import React, { useCallback, useEffect, useState } from 'react';
import { Helmet } from 'react-helmet';
import PdfDocument from './components/PdfDocument';
import ReaderSearchBar from './components/ReaderSearchBar';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';
import DocumentSearch from '../reader/DocumentSearch';

import { useDispatch, useSelector } from 'react-redux';
import { ACTION_NAMES, CATEGORIES, INTERACTION_TYPES } from '../reader/analytics';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import { setZoomLevel, togglePdfSidebar, toggleSearchBar } from '../reader/PdfViewer/PdfViewerActions';
import DeleteModal from './components/Comments/DeleteModal';
import ShareModal from './components/Comments/ShareModal';
import { hideSideBarSelector, scaleSelector, showSideBarSelector, storeDocumentsSelector } from './selectors';
import { getRotationDeg } from './util/documentUtil';
import { ZOOM_INCREMENT, ZOOM_LEVEL_MAX, ZOOM_LEVEL_MIN } from './util/readerConstants';
import _ from 'lodash';
import { getFilteredDocuments } from '../reader/selectors';
import { ExternalLinkIcon } from '../components/icons/ExternalLinkIcon';
import { pdfToolbarStyles, pdfUiClass, pdfWrapper } from './styles';
import Link from '../components/Link';
import Button from '../components/Button';
import { LeftChevronIcon } from '../components/icons/LeftChevronIcon';
import DocumentCategoryIcons from '../reader/DocumentCategoryIcons';
import { rotateDocument } from '../reader/Documents/DocumentsActions';
import { FitToScreenIcon } from '../components/icons/FitToScreenIcon';
import { DownloadIcon } from '../components/icons/DownloadIcon';
import { SearchIcon } from '../components/icons/SearchIcon';
import { RotateIcon } from '../components/icons/RotateIcon';
import R2SideBar from './R2SideBar';
import DocumentLoadError from './components/DocumentLoadError';

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const showSideBar = useSelector(showSideBarSelector);
  const dispatch = useDispatch();

  const currentDocId = Number(props.match.params.docId);
  const currentDocumentId = Number(props.match.params.docId);

  const docList = useSelector(getFilteredDocuments);
  const scale = useSelector(scaleSelector);
  const rotation = _.get(useSelector(storeDocumentsSelector), [currentDocId, 'rotation']);
  const doc = docList.find((x) => x.id === currentDocId);
  const currentDocIndex = docList.indexOf(doc);
  const prevDoc = docList?.[currentDocIndex - 1];
  const nextDoc = docList?.[currentDocIndex + 1];
  const hideSideBar = useSelector(hideSideBarSelector);

  useEffect(() => {
    setShowSearchBar(false);
  }, [currentDocumentId]);

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setShowSearchBar(false);
      }
      const metaKey = navigator.appVersion.includes('Win') ? 'ctrlKey' : 'metaKey';

      if (event[metaKey] && event.code === 'KeyF') {
        event.preventDefault();
        setShowSearchBar(true);
      }

      if (event.altKey && event.code === 'Backspace') {
        window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
        props.history.push(props.documentPathBase);
      }

      if (event.altKey && event.code === 'KeyM' && !event.shiftKey) {
        dispatch(togglePdfSidebar());
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, []);

  const ZOOM_RATE = 0.3;
  const MINIMUM_ZOOM = 0.1;

  let vals = [];
  const setCurrentPageOnScroll = useCallback((pageNum) => {
    let timeout;

    vals.push(pageNum);

    const delayed = () => {
      if (vals.length) {
        const lowestPage = Math.min(...vals);

        setCurrentPage(lowestPage);
        vals = [];
        clearTimeout(timeout);
      }
    };

    clearTimeout(timeout);
    timeout = setTimeout(delayed, 50);
  });

  const fitToScreen = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');
    dispatch(setZoomLevel(1));
  };

  useEffect(() => {
    document.body.style.overflow = 'hidden';

    return () => document.body.style.overflow = 'auto';
  }, [window.location.pathname]);

  useEffect(() => {
    dispatch(stopPlacingAnnotation('navigation'));
  }, [doc.id, dispatch]);

  const getPrefetchFiles = () => _.compact(_.map([prevDoc, nextDoc], 'content_url'));

  const files = props.featureToggles.prefetchDisabled ?
    [doc.content_url] :
    [...getPrefetchFiles(), doc.content_url];

  const showPreviousDocument = () => {
    window.analyticsEvent(
      CATEGORIES.VIEW_DOCUMENT_PAGE,
      ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
      INTERACTION_TYPES.VISIBLE_UI
    );
    props.showPdf(prevDoc.id)();
    dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
  };

  const showNextDocument = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, ACTION_NAMES.VIEW_NEXT_DOCUMENT, INTERACTION_TYPES.VISIBLE_UI);
    props.showPdf(nextDoc.id)();
    dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
  };

  // TOOLBAR functions
  const openDownloadLink = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');
    window.open(`${doc.content_url}?type=${doc.type}&download=true`);
  };

  const onBackToClaimsFolder = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
    dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
  };

  const handleClickDocumentTypeLink = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'document-type-link');
  };

  const zoom = (delta) => () => {
    const nextScale = Math.max(MINIMUM_ZOOM, _.round(scale + delta, 2));
    const zoomDirection = delta > 0 ? 'in' : 'out';

    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${zoomDirection}`, nextScale);
    dispatch(setZoomLevel(nextScale));
  };

  return (
    <>
      <Helmet key={doc?.id}>
        <title>{`${(doc?.type) || ''} | Document Viewer | Caseflow Reader`}</title>
      </Helmet>
      <div className="cf-pdf-page-container">
        <div className={pdfUiClass(hideSideBar)} {...pdfWrapper}>
          <div className="cf-pdf-header cf-pdf-toolbar">
            <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarLeft}>
              { props.allDocuments.length > 1 &&
              <Link
                to={`${props.documentPathBase}`}
                name="backToClaimsFolder"
                button="matte"
                onClick={onBackToClaimsFolder}>
                <LeftChevronIcon />
                &nbsp; Back
              </Link> }
            </span>
            <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarCenter}>
              <span className="category-icons-and-doc-type">
                <span className="cf-pdf-doc-category-icons">
                  <DocumentCategoryIcons doc={doc} />
                </span>
                <span className="cf-pdf-doc-type-button-container">
                  <Link
                    name="newTab"
                    ariaLabel="open document in new tab"
                    target="_blank"
                    button="matte"
                    onClick={handleClickDocumentTypeLink}
                    href={`/reader/appeal${props.documentPathBase}/${doc.id}`}>
                    <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
                      <span title="Open in new tab">{doc.type}</span>
                      <span className="cf-pdf-external-link-icon"><ExternalLinkIcon /></span>
                    </h1>
                  </Link>
                </span>
              </span>
            </span>
            <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarRight}>
              <span className="cf-pdf-button-text">Zoom: {scale}</span>
              <Button
                name="zoomOut"
                classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
                onClick={zoom(-ZOOM_RATE)}
                ariaLabel="zoom out">
                <i className="fa fa-minus" aria-hidden="true" />
              </Button>
              <Button
                name="zoomIn"
                classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
                onClick={zoom(ZOOM_RATE)}
                ariaLabel="zoom in">
                <i className="fa fa-plus" aria-hidden="true" />
              </Button>
              <Button
                name="fit"
                classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
                onClick={fitToScreen}
                ariaLabel="fit to screen">
                <FitToScreenIcon />
              </Button>
              <Button
                name="rotation"
                classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
                onClick={() => dispatch(rotateDocument(doc.id))}
                ariaLabel="rotate document">
                <span>{rotation ? 0 : rotation}</span><RotateIcon />
              </Button>
              <span className="cf-pdf-spaced-buttons">|</span>
              <Button
                name="download"
                classNames={['cf-pdf-button cf-pdf-download-icon']}
                onClick={openDownloadLink}
                ariaLabel="download pdf">
                <DownloadIcon />
              </Button>
              <Button
                name="search"
                classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small']}
                ariaLabel="search text"
                type="submit"
                onClick={() => dispatch(toggleSearchBar())}>
                <SearchIcon />
              </Button>
              {hideSideBar && (
                <span {...pdfToolbarStyles.openSidebarMenu}>
                  <Button
                    name="open sidebar menu"
                    classNames={['cf-pdf-button']}
                    onClick={() => dispatch(togglePdfSidebar())}>
                    <strong>
                      Open menu
                    </strong>
                  </Button>
                </span>
              )}
            </span>
          </div>
          <div>
            <DocumentSearch file={doc.content_url} featureToggles={props.featureToggles} />
          </div>
          <div className="cf-pdf-scroll-view">
            <div
              id={doc.content_url}
              style={{
                position: 'relative',
                width: '100%',
                height: '100%',
              }}
            >
              {files.map((file) =>
                (
                  <PdfDocument
                    currentPage={currentPage}
                    doc={doc}
                    key={file}
                    rotateDeg={rotateDeg}
                    setCurrentPage={setCurrentPageOnScroll}
                    zoomLevel={props.zoomLevel}
                    isVisible={doc.content_url === file}
                    showPdf={props.showPdf}
                    featureToggles={props.featureToggles}
                    rotation={rotation}
                    scale={scale}
                  />
                ))}
            </div>
          </div>
        </div>
        <R2SideBar
          doc={doc}
          fetchAppealDetails={props.fetchAppealDetails}
          onJumpToComment={props.onJumpToComment}
          featureToggles={props.featureToggles}
          vacolsId={props.match.params.vacolsId}
        />
        <DeleteModal documentId={currentDocumentId} />
        <ShareModal />
      </div>
    </>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array,
  documentPathBase: PropTypes.string,
  featureToggles: PropTypes.object,
  fetchAppealDetails: PropTypes.func,
  history: PropTypes.any,
  showPdf: PropTypes.func,
  match: PropTypes.object,
  zoomLevel: PropTypes.number,
  onZoomChange: PropTypes.func,
  onJumpToComment: PropTypes.func,
};

export default DocumentViewer;
