import PropTypes from 'prop-types';
import React, { useEffect, useState, useRef } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/pdfjs/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import DocumentLoadError from './DocumentLoadError';
import { useDispatch } from 'react-redux';
import { selectCurrentPdf } from 'app/reader/Documents/DocumentsActions';
import { storeMetrics } from '../../util/Metrics';
import { clearPdfDocument, setDocumentLoadError, setPageDimensions, setPdfDocument } from '../../reader/Pdf/PdfActions';
import _ from 'lodash';
import { PAGE_DIMENSION_SCALE } from '../../reader/constants';

let loadingTask = null;
let pdfDocument = null;

const PdfDocument = ({
  currentPage,
  doc,
  isDocumentLoadError,
  rotateDeg,
  setIsDocumentLoadError,
  setNumPages,
  setCurrentPage,
  zoomLevel }) => {
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);
  const dispatch = useDispatch();
  const pdfMetrics = useRef({ renderedPageCount: 0, renderedTimeTotal: 0 });
  const [allPagesRendered, setAllPagesRendered] = useState(false);
  const [metricsLogged, setMetricsLogged] = useState(false);
  const metricsLoggedRef = useRef(metricsLogged);

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
  };

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

  const onRejected = (reason, step) => {
    console.error(`DOC ID: ${doc.id} | GET ${props.file} : STEP ${step} : ${reason}`);
    throw reason;
  };

  const getPagesPromise = () => {
    const promises = _.range(0, pdfDocument?.numPages).map((index) => {

      return pdfDocument.getPage(index + 1);
    });

    return Promise.all(promises);
  };

  const setPageDimensionsForPdf = (pages) => {
    const viewports = pages.map((page) => {
      return _.pick(page.getViewport({ scale: PAGE_DIMENSION_SCALE }), ['width', 'height']);
    });

    setPageDimensions(doc.content_url, viewports);
  };

  const getPdfDoc = () => {
    const requestOptions = {
      cache: true,
      withCredentials: true,
      timeout: true,
      responseType: 'arraybuffer',
    };

    return ApiUtil.get(doc.content_url, requestOptions).
      then((resp) => {
        loadingTask = getDocument({ data: resp.body, pdfBug: true, verbosity: 0 });

        return loadingTask.promise;

      }, (reason) => onRejected(reason, 'getDocument')).
      then((pdfjsDocument) => {

        pdfDocument = pdfjsDocument;
        setPdfDoc(pdfjsDocument);
        setNumPages(pdfjsDocument.numPages);

        return getPagesPromise(pdfDocument);
      }, (reason) => onRejected(reason, 'getPdfJsDoc')).
      then((pages) => {
        setPdfPages(pages);

        return setPageDimensionsForPdf(pages);
      }, (reason) => onRejected(reason, 'setPageDimensions')).
      then(() => {
        if (loadingTask.destroyed) {
          return pdfDocument.destroy();
        }
        loadingTask = null;

        return setPdfDocument(doc.content_url, pdfDocument);
      }, (reason) => onRejected(reason, 'setPdfDocument')).
      catch((error) => {
        const message = `READERLOG ERROR Fetching document failed for ${doc.content_url} : ${error}`;

        console.error(message);
        if (loadingTask) {
          loadingTask.destroy();
        }
        if (pdfDocument) {
          pdfDocument.destroy();
          clearPdfDocument(doc.content_url, pdfDocument);
        }
        loadingTask = null;
        setDocumentLoadError(doc.content_url);
      });
  };

  useEffect(() => {
    // const getDocData = async () => {
    //   pdfMetrics.current.renderedPageCount = 0;
    //   pdfMetrics.current.renderedTimeTotal = 0;
    //   setPdfDoc(null);
    //   setPdfPages([]);
    //   setAllPagesRendered(false);
    //   setMetricsLogged(false);
    //   const requestOptions = {
    //     cache: true,
    //     withCredentials: true,
    //     timeout: true,
    //     responseType: 'arraybuffer',
    //   };

    //   pdfMetrics.current.getStartTime = new Date().getTime();
    //   const byteArr = await ApiUtil.get(doc.content_url, requestOptions).then((response) => {
    //     return response.body;
    //   });

    //   pdfMetrics.current.getEndTime = new Date().getTime();
    //   const docProxy = await getDocument({ data: byteArr, pdfBug: true, verbosity: 0 }).promise;

    //   if (docProxy) {
    //     setPdfDoc(docProxy);
    //     setNumPages(docProxy.numPages);
    //   }
    // };

    // getDocData().catch((error) => {
    //   console.error(`ERROR with getting doc data: ${error}`);
    //   setIsDocumentLoadError(true);
    // });

    getPdfDoc();

    return () => {
      if (loadingTask) {
        loadingTask.destroy();
      }
      if (pdfDocument) {
        pdfDocument.destroy();
        clearPdfDocument(doc.content_url, pdfDocument);
      }
    };
  }, [doc.content_url]);

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

  return (
    <div id="pdfContainer" style={containerStyle}>
      {isDocumentLoadError && <DocumentLoadError doc={doc} />}
      {pdfPages.map((page, index) => (
        <Page
          setCurrentPage={setCurrentPage}
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`doc-${doc.id}-page-${index}`}
          renderItem={(childProps) => (
            <Layer isCurrentPage={currentPage === page.pageNumber}
              documentId={doc.id} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
              <TextLayer page={page} zoomLevel={zoomLevel} rotation={rotateDeg} />
            </Layer>
          )}
          setRenderingMetrics={handleRenderingMetrics}
        />
      ))}
    </div>
  );
};

PdfDocument.propTypes = {
  currentPage: PropTypes.number,
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.number,
    type: PropTypes.string,
  }),
  isDocumentLoadError: PropTypes.bool,
  rotateDeg: PropTypes.string,
  setIsDocumentLoadError: PropTypes.func,
  setNumPages: PropTypes.func,
  setCurrentPage: PropTypes.func,
  zoomLevel: PropTypes.number,
};

export default PdfDocument;
