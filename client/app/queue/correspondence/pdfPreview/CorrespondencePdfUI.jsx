import React, { useEffect, useMemo, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import * as pdfjs from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
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
 * @param {Object} documents - Document metadata obtained from Document Controller
 * @param {string} documentPathBase - String path containing appeal Id. Directs to /:appeal_id/documents
 */
const CorrespondencePdfUI = (props) => {
  // Note: Replace hard-coded data objects to dynamically include actual API request data

  // Destructured Props and State
  const {
    documents,
    selectedId
  } = props;

  const mappedMockDocumentData = documents.map((doc, index) => {
    return (
      {
        id: doc.correspondence_id,
        type: doc.document_title,
        content_url: `/queue/correspondence/${index + 1}/pdf`
      }
    );
  });
  // Hard Coded Temp Data Objects
  const documentPathBase = '/2941741/documents';

  // useRefs (persist data through React render cycle)
  // Contains a ref to each canvas DOM element generated after document loads
  const canvasRefs = useRef([]);
  const gridRef = useRef(null);
  const scrollViewRef = useRef(null);
  const viewportRef = useRef({
    height: PDF_PAGE_HEIGHT,
    width: PDF_PAGE_WIDTH
  });

  // useStates (re-renders components on change)

  const [scale, setScale] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [pdfDocProxy, setPdfDocProxy] = useState(null);
  const [pdfPageProxies, setPdfPageProxies] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [loadError, setLoadError] = useState(false);

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

    // Note: Refactor when CorrespondenceDocument controller is created
    // Note: Need to add error handling
    const loadPdf = async () => {
      try {
        const response = await ApiUtil.get(`${mappedMockDocumentData[selectedId].content_url}`, {
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
        setLoadError(false);
      } catch (error) {
        setLoadError(true);
      }
    };

    loadPdf();

  }, [selectedId]);

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
    const pageOffset = Math.floor(scrolledHeight / viewportRef.current.height);

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

    // Scrollheight - 750px (height set by CSS) represents the maximum scrollable height of the grid container
    // When we hit the maximum scrollable height, the first page number of the last row should be displayed
    if ((scrollViewRef.current.scrollHeight - 749 === scrolledHeight)) {
      currentRowNumber = Math.ceil(pdfDocProxy.numPages / 2);

    // Correct for "page 0" base case
    } else if (scrolledHeight > viewportRef.current.height) {
      // Calculates the current visible rowNumber starting from 1, which contains two pages
      currentRowNumber = Math.ceil(scrolledHeight / viewportRef.current.height);
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
    // Make generic key to map
    const key = index + 123;

    return (
      <CorrespondencePdfPage
        key={`pdf-page-key-${key}`}
        canvasRefs={canvasRefs}
        page={page}
        index={index}
        scale={scale}
        rotation={rotation}
        viewportRef={viewportRef}
      />
    );
  }, [pdfDocProxy, pdfPageProxies]));

  if (!pdfDocProxy || !pdfPageProxies) {
    return <div></div>;
  }

  if (loadError) {
    return <div>Document could not be loaded, please try again later</div>;
  }

  return (
    <div className="cf-pdf-preview-container pdf-wrapper">
      <CorrespondencePdfToolBar
        doc={mappedMockDocumentData[selectedId]}
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

CorrespondencePdfUI.propTypes = {
  documents: PropTypes.array,
  selectedId: PropTypes.number
};

export default CorrespondencePdfUI;
