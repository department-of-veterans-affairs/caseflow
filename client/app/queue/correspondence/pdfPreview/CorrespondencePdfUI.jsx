import React, { useEffect, useMemo, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import * as pdfjs from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
import { css } from 'glamor';
import _ from 'lodash';
import CorrespondencePdfToolBar from './CorrespondencePdfToolBar';
import ApiUtil from '../../../util/ApiUtil';
import { pageNumberOfPageIndex } from '../../../reader/utils';
import { PDF_PAGE_HEIGHT, PDF_PAGE_WIDTH } from '../../../reader/constants';
import { CorrespondencePdfFooter } from './CorrespondencePdfFooter';
import CorrespondencePdfPage from './CorrespondencePdfPage';

pdfjs.GlobalWorkerOptions.workerSrc = pdfjsWorker;

/**
 * Represents the root layout and component structure for viewing PDF files
 * @param {Object} doc - Document metadata obtained from Document Controller
 * @param {string} documentPathBase - String path containing appeal Id. Directs to /:appeal_id/documents
 */
const CorrespondencePdfUI = () => {
  // TODO: Replace hard-coded data objects to dynamically include actual API request data

  // Destructured Props and State
  // const {
  //   documentPathBase,
  //   doc
  // } = props;

  // Hard Coded Temp Data Objects
  const documentPathBase = '/2941741/documents';
  const doc = {
    id: 13,
    category_medical: null,
    category_other: null,
    category_procedural: null,
    created_at: '2023-11-16T10:08:41.948-05:00',
    description: null,
    file_number: '686623298',
    previous_document_version_id: null,
    received_at: '2023-11-17',
    series_id: '4230620',
    type: 'Private Medical Treatment Record',
    updated_at: '2023-11-20T14:58:49.681-05:00',
    upload_date: '2023-11-18',
    vbms_document_id: '110',
    content_url: '/document/13/pdf',
    filename: 'filename-9265746.pdf',
    category_case_summary: true,
    serialized_vacols_date: '',
    serialized_receipt_date: '11/17/2023',
    'matching?': false,
    opened_by_current_user: true,
    tags: [],
    receivedAt: '2023-11-17',
    listComments: false,
    wasUpdated: false
  };

  // useRefs (persist data through React render cycle)
  // Contains a ref to each canvas DOM element generated after document loads
  const canvasRefs = useRef([]);
  const gridRef = useRef(null);
  const scrollViewRef = useRef(null);

  // useStates (re-renders components on change)
  const [viewportState, setViewPortState] = useState({
    height: PDF_PAGE_HEIGHT,
    width: PDF_PAGE_WIDTH
  });

  const [scale, setScale] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [pdfDocProxy, setPdfDocProxy] = useState(null);
  const [pdfPageProxies, setPdfPageProxies] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);

  // Once the component loads, we fetch the document from the Document Controller
  // and retrieve the document content via pdfjs library's PdfDocumentProxy object.
  // See https://mozilla.github.io/pdf.js/api/draft/module-pdfjsLib-PDFDocumentProxy.html
  useEffect(() => {

    // Retrieves all pdfPageProxy objects from pdfDocumentProxy
    const getAllPages = async (pdfDocument) => {
      const promises = _.range(0, pdfDocument?.numPages).map((index) => {
        return pdfDocument.getPage(pageNumberOfPageIndex(index));
      });

      return Promise.all(promises);
    };

    // TODO: Refactor when CorrespondenceDocument controller is created
    const loadPdf = async () => {
      // Currently pulls from Reader Document controller at route => document/:document_id/pdf
      const response = await ApiUtil.get(`${doc.content_url}`, {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      });
      const loadingTask = pdfjs.getDocument({ data: response.body });
      const pdfDocument = await loadingTask.promise;

      const pages = await getAllPages(pdfDocument);

      setPdfDocProxy(pdfDocument);
      setPdfPageProxies(pages);
    };

    loadPdf();

    return () => {
      pdfDocProxy.destroy();
    };
  }, []);


  // ////////////// //
  //   Constants    //
  // ////////////// //
  const ZOOM_RATE = 0.3;
  const MINIMUM_ZOOM = 0.4;
  const MAXIMUM_ZOOM = 5.0;

  // Once the scrollview div containers exceeds 1300px, it will run a css container query to render a 2 column grid
  const OFFSET_WIDTH = 1300;
  const isScrollViewAGrid = scrollViewRef?.current?.offsetWidth >= OFFSET_WIDTH;

  const ROTATION_INCREMENTS = 90;
  const COMPLETE_ROTATION = 360;

  const pdfWrapper = css({
    '@media(max-width: 920px)': {
      width: 'unset',
      right: '250px' },
    '@media(min-width: 1240px )': {
      width: 'unset',
      right: '380px' }
  });

  // ////////////// //
  // PDF Functions  //
  // ////////////// //

  // Zoom
  const zoomOut = () => {
    const nextScale = Math.max(MINIMUM_ZOOM, _.round(scale - ZOOM_RATE, 2));

    setScale(nextScale);
  };

  const zoomIn = () => {
    const nextScale = Math.min(MAXIMUM_ZOOM, _.round(scale + ZOOM_RATE, 2));

    setScale(nextScale);
  };

  const fitToScreen = () => {
    setScale(1);
  };

  // Rotations
  const handleDocumentRotation = () => {
    //
    setRotation((prev) => (prev + ROTATION_INCREMENTS) % COMPLETE_ROTATION);
  };

  // Footer Pagination
  const handleSetCurrentPage = (pageInput) => {
    // PageInput must be a valid integer within the range of the document pages
    // Check the canvasRefs to ensure that this function is ran after the canvases have been rendered
    if ((canvasRefs.current.length > 0) && (pdfDocProxy.numPages >= pageInput > 0) && Number.isInteger(pageInput)) {
      const selectedPage = document.getElementById(`canvas-${pageInput}`);

      selectedPage.scrollIntoView();
    }
    setCurrentPage(pageInput);
  };

  // Scrolling
  const handleScroll = () => {
    // Amount of Pixels that have been scrolled already from the top
    const scrolledHeight = scrollViewRef.current.scrollTop;
    const pageOffset = Math.floor(scrolledHeight / viewportState.height);

    // Scrollheight - 750px (height set by CSS) represents the maximum scrollable height of the grid container
    // When we hit the maximum scrollable height, the last page number should be displayed
    if ((scrollViewRef.current.scrollHeight - 750 === scrolledHeight) && (currentPage !== pdfDocProxy.numPages)) {
      setCurrentPage(pdfDocProxy.numPages);
    } else {
      const pageNumber = pageOffset + 1;

      setCurrentPage(pageNumber);
    }
  };

  const handleGridScroll = () => {
    // Amount of Pixels that have been scrolled already from the top
    const scrolledHeight = scrollViewRef.current.scrollTop;
    let currentRowNumber = 1;
    console.log(currentPage)
    // Scrollheight - 750px (height set by CSS) represents the maximum scrollable height of the grid container
    // When we hit the maximum scrollable height, the first page number of the last row should be displayed
    if ((scrollViewRef.current.scrollHeight - 749 === scrolledHeight)) {
      currentRowNumber = Math.ceil(pdfDocProxy.numPages / 2);

    // Correct for "page 0" base case
    } else if (scrolledHeight > viewportState.height) {
      // Calculates the current visible rowNumber starting from 1, which contains two pages
      currentRowNumber = Math.ceil(scrolledHeight / viewportState.height);
    }

    // By default, we will display the page number of the first page in each row
    const pageNumber = (currentRowNumber * 2) - 1;

    // We only set the page number if it is not equal to either pages in the row
    if ((currentPage !== pageNumber) && (currentPage !== (pageNumber + 1))) {
      setCurrentPage(pageNumber);
    }
  };

  // Memoize components after render to keep canvas references
  const generatePdfPages = useMemo(() => pdfPageProxies?.map((page, index) => {
    return (
      <CorrespondencePdfPage
        key={`pdf-page-key-${index}`}
        canvasRefs={canvasRefs}
        page={page}
        index={index}
        scale={scale}
        rotation={rotation}
        viewportState={viewportState}
      />
    );
  }, [pdfDocProxy, pdfPageProxies]));

  if (!pdfDocProxy || !pdfPageProxies) {
    return <div>Loading...</div>;
  }

  return (
    <div className="cf-pdf-preview-container" {...pdfWrapper}>
      <CorrespondencePdfToolBar
        doc={doc}
        documentPathBase={documentPathBase}
        zoomIn={zoomIn}
        zoomOut={zoomOut}
        fitToScreen={fitToScreen}
        handleDocumentRotation={handleDocumentRotation}
      />
      <div>
        <div className="cf-pdf-preview-scrollview"
          ref={scrollViewRef}
          onScroll={isScrollViewAGrid ? handleGridScroll : handleScroll}
        >
          <div className="cf-pdf-preview-grid" ref={gridRef}>
            { generatePdfPages }
          </div>
        </div>
        <CorrespondencePdfFooter
          currentPage={currentPage}
          pdfDocProxy={pdfDocProxy}
          handleSetCurrentPage={handleSetCurrentPage}
        />
      </div>
    </div>
  );
};

export default CorrespondencePdfUI;
