import PropTypes from 'prop-types';
import React, { memo, useEffect, useMemo, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/pdfjs/pdf.worker.min.js';

import { selectCurrentPdf } from 'app/reader/Documents/DocumentsActions';
import {
  clearDocumentLoadError,
  clearPdfDocument,
  setDocumentLoadError,
  setPdfDocument
} from '../../reader/Pdf/PdfActions';
import { getDocumentText } from '../../reader/PdfSearch/PdfSearchActions';
import { getPageIndexWithMatch } from '../../reader/selectors';
import ApiUtil from '../../util/ApiUtil';
import { storeMetrics } from '../../util/Metrics';
import { annotationPlacement, pdfSelector } from '../selectors';
import Layer from './Comments/Layer';
import DocumentLoadError from './DocumentLoadError';
import Page from './Page';
import TextLayer from './TextLayer';

const PdfDocument = memo(({
  currentPage,
  doc,
  file,
  rotateDeg,
  setCurrentPage,
  zoomLevel,
}) => {

  /* eslint-disable camelcase */
  const isFileVisible = doc?.content_url === file;

  const containerStyle = {
    width: '100%',
    height: '100%',
    overflow: 'auto',
    paddingTop: '10px',
    paddingLeft: '6px',
    paddingRight: '6px',
    alignContent: 'start',
    justifyContent: 'center',
    gap: '8rem',
    visibility: `${isFileVisible ? 'visible' : 'hidden'}`,
    margin: '0 auto',
    marginBottom: '-25px',
    position: 'absolute',
    top: 0,
    left: 0,
  };

  const { isPlacingAnnotation } = useSelector(annotationPlacement);

  useEffect(() => {
    const keyHandler = (event) => {
      if (isFileVisible && !isPlacingAnnotation && event.code === 'PageDown') {
        const listItems = document.querySelectorAll('.prototype-canvas-wrapper.visible-page');

        document.getElementById(`canvasWrapper-${currentPage + listItems.length}`)?.scrollIntoView();
        event.preventDefault();
      }

      if (isFileVisible && !isPlacingAnnotation && event.code === 'PageUp') {
        const listItems = document.querySelectorAll('.prototype-canvas-wrapper.visible-page');

        document.getElementById(`canvasWrapper-${currentPage - listItems.length}`)?.scrollIntoView();
        event.preventDefault();
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, [currentPage]);

  const dispatch = useDispatch();
  const pageIndexWithMatch = useSelector(getPageIndexWithMatch);
  const { pdfDocs, docLoadErrors } = useSelector(pdfSelector);

  /* eslint-disable camelcase */
  const isLoadError = docLoadErrors[doc?.content_url];

  const [allPagesRendered, setAllPagesRendered] = useState(false);
  const [metricsLogged, setMetricsLogged] = useState(false);
  const [pdfPages, setPdfPages] = useState([]);
  const [textContent, setTextContent] = useState([]);

  const metricsLoggedRef = useRef(metricsLogged);
  const pdfMetrics = useRef({ renderedPageCount: 0, renderedTimeTotal: 0 });
  const pdfDocumentRef = useRef(null);
  const pdfLoadingTaskRef = useRef(null);

  const handleRenderingMetrics = (renderingTime) => {
    if (renderingTime) {
      pdfMetrics.current.renderedTimeTotal += renderingTime;
      pdfMetrics.current.renderedPageCount += 1;
      if (pdfMetrics.current.renderedPageCount === pdfPages.length && pdfPages.length > 0) {
        setAllPagesRendered(true);
      }
    }
  };

  const getFirstPageOverallTime = () => {
    if (pdfPages && pdfPages.length > 0) {
      const firstPageStats = pdfPages[0]?._stats;

      if (firstPageStats && Array.isArray(firstPageStats.times)) {

        const overallTime = firstPageStats.times.find((time) => time.name === 'Overall');

        if (overallTime) {
          return overallTime.end - overallTime.start;
        }
      }
    }

    return 0;
  };

  const logMetrics = () => {
    const calculatedAverage = Math.round(
      pdfMetrics.current.renderedPageCount > 0 ?
        pdfMetrics.current.renderedTimeTotal / pdfMetrics.current.renderedPageCount : 0
    );

    storeMetrics(
      doc.id,
      {
        document_request_time: pdfMetrics.current.getEndTime - pdfMetrics.current.getStartTime,
        number_of_pages_rendered: pdfMetrics.current.renderedPageCount,
        rendering_time_for_allPages: pdfMetrics.current.renderedTimeTotal,
        average_rendering_time_per_page: calculatedAverage,
        first_page_overall_time: getFirstPageOverallTime(),
      },
      {
        message: 'Reader Prototype times in milliseconds',
        type: 'performance',
        product: 'reader prototype',
        start: null,
        end: null,
        duration: null,
      },
      null
    );

    setMetricsLogged(true);
  };

  const requestOptions = {
    cache: true,
    withCredentials: true,
    timeout: true,
    responseType: 'arraybuffer',
  };

  const getPdfDocument = async (url) => {
    pdfMetrics.current.renderedPageCount = 0;
    pdfMetrics.current.renderedTimeTotal = 0;
    setPdfPages([]);
    setTextContent([]);
    setAllPagesRendered(false);
    setMetricsLogged(false);

    pdfMetrics.current.getStartTime = new Date().getTime();
    await ApiUtil.get(url, requestOptions).
      then((response) => {
        pdfLoadingTaskRef.current = getDocument({ data: response.body, pdfBug: true, verbosity: 0 });
      }).
      catch((error) => {
        console.error(`ERROR with fetching doc from document API: ${error}`);
        dispatch(setDocumentLoadError(doc.content_url));
      });

    pdfMetrics.current.getEndTime = new Date().getTime();
    await pdfLoadingTaskRef.current?.promise.
      then((pdfDocument) => {
        if (!pdfDocument) {
          return dispatch(setDocumentLoadError(doc.content_url));
        }

        dispatch(setPdfDocument(url, pdfDocument));
        pdfDocumentRef.current = pdfDocument;
      }).
      catch((err) => {
        console.error(`ERROR with PDFJS for ${doc.content_url}: ${err}`);
        dispatch(clearPdfDocument(doc.content_url, pdfDocumentRef.current));

        return null;
      });
  };

  const getPdfPages = (pdfDocument) => {
    let promises = [];
    let textContentContainer = [];

    for (let i = 0; i < pdfDocument?.numPages; i++) {
      promises.push(pdfDocument.getPage(i + 1));
    }

    Promise.all(promises).
      then((pages) => {
        setPdfPages(pages);
        for (let i = 0; i < pages.length; i++) {
          pages[i].getTextContent().then((text) => {
            textContentContainer[i] = text;
          });
        }
        if (isFileVisible) {
          setTextContent(textContentContainer);
        }
      });
  };

  // if the doc has already been saved to the redux store (in pdfDocs)
  // then do not call getPdfDocument()
  // call getPdfPages() to render pages only if file is visible
  useMemo(() => {
    if (pdfDocs?.[file]) {
      pdfDocumentRef.current = pdfDocs?.[file];
      if (isFileVisible) {
        getPdfPages(pdfDocs?.[file]);
        dispatch(getDocumentText(pdfDocumentRef.current, doc.content_url));
      }
    } else {
      getPdfDocument(file);
    }
  }, [file]);

  // render pages when user clicking next/previous
  useMemo(() => {
    if (pdfDocs?.[doc.content_url] && isFileVisible) {
      getPdfPages(pdfDocs?.[doc.content_url]);
      dispatch(getDocumentText(pdfDocumentRef.current, doc.content_url));
    }
  }, [doc.content_url]);

  // initial load page render
  useMemo(() => {
    if (pdfDocumentRef.current && isFileVisible) {
      getPdfPages(pdfDocumentRef.current);
      dispatch(getDocumentText(pdfDocumentRef.current, doc.content_url));
    }
  }, [pdfDocumentRef.current]);

  useEffect(() => {
    clearDocumentLoadError(file);

    return () => {
      if (pdfLoadingTaskRef.current?.id === pdfDocumentRef.current?.loadingTask?.docId) {
        pdfLoadingTaskRef.current?.destroy();
        pdfDocumentRef.current?.destroy();
        pdfLoadingTaskRef.current = null;
        pdfDocumentRef.current = null;
      }
    };
  }, [file]);

  useEffect(() => {
    dispatch(selectCurrentPdf(doc.id));
  }, [doc.id]);

  useEffect(() => {
    if (allPagesRendered && !metricsLogged) {
      logMetrics();
    }
  }, [allPagesRendered, metricsLogged]);

  useEffect(() => {
    return () => {
      if (!metricsLoggedRef.current) {
        logMetrics();
      }
    };
  }, [doc.id]);

  useEffect(() => {
    metricsLoggedRef.current = metricsLogged;
  }, [metricsLogged]);

  const renderPages = () => {
    // eslint-disable-next-line no-underscore-dangle
    if (isFileVisible && pdfDocumentRef.current && !pdfDocumentRef.current._transport.destroyed) {
      return pdfPages.map((page, index) => (
        <Page
          setCurrentPage={setCurrentPage}
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`doc-${doc.id}-page-${index + 1}`}
          renderItem={(childProps) => (
            <Layer isCurrentPage={currentPage === page.pageNumber}
              documentId={doc.id} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
              <TextLayer
                textContent={textContent[index]}
                zoomLevel={zoomLevel}
                rotation={rotateDeg}
                viewport={page.getViewport({ scale: 1 })}
                hasSearchMatch={pageIndexWithMatch === index + 1}
              />
            </Layer>
          )}
          setRenderingMetrics={handleRenderingMetrics}
        />
      ));
    }
  };

  return (
    <div id={isFileVisible ? 'pdfContainer' : ''} className={file} style={containerStyle}>
      {isLoadError ? <DocumentLoadError doc={doc} /> : renderPages()}
    </div>
  );
});

PdfDocument.propTypes = {
  currentPage: PropTypes.number,
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.number,
    type: PropTypes.string,
  }),
  file: PropTypes.string,
  isFileVisible: PropTypes.bool,
  rotateDeg: PropTypes.string,
  setCurrentPage: PropTypes.func,
  showPdf: PropTypes.func,
  zoomLevel: PropTypes.number,
};

export default PdfDocument;
