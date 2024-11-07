import PropTypes from 'prop-types';
import React, { useEffect, useState, useRef } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/pdfjs/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import DocumentLoadError from './DocumentLoadError';
import { useDispatch, useSelector } from 'react-redux';
import { selectCurrentPdf } from 'app/reader/Documents/DocumentsActions';
import { storeMetrics } from '../../util/Metrics';
import _ from 'lodash';
import ReaderFooter from './ReaderFooter';
import { setDocumentLoadError } from '../../reader/Pdf/PdfActions';
import R2PdfPage from '../R2PdfPage';
import { scaleSelector } from '../selectors';

const PdfDocument = ({
  currentPage,
  doc,
  setCurrentPage,
  isVisible,
  showPdf,
  featureToggles,
  rotation,
  scale,
}) => {

  if (!isVisible) {
    return null;
  }
  const dispatch = useDispatch();
  const [isDocumentLoadError, setIsDocumentLoadError] = useState(false);
  const [pdfPages, setPdfPages] = useState([]);
  const [allPagesRendered, setAllPagesRendered] = useState(false);
  const [metricsLogged, setMetricsLogged] = useState(false);

  const loadingTaskRef = useRef(null);
  const pdfDocumentRef = useRef(null);
  const pdfMetrics = useRef({ renderedPageCount: 0, renderedTimeTotal: 0 });
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
    visibility: `${isVisible}`,
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

  const getPdfDoc = () => {
    pdfMetrics.current.renderedPageCount = 0;
    pdfMetrics.current.renderedTimeTotal = 0;
    setAllPagesRendered(false);
    setMetricsLogged(false);

    const requestOptions = {
      cache: true,
      withCredentials: true,
      timeout: true,
      responseType: 'arraybuffer',
    };

    pdfMetrics.current.getStartTime = new Date().getTime();

    return ApiUtil.get(doc.content_url, requestOptions). // todo setIsDocumentLoadError here
      then((resp) => {
        pdfMetrics.current.getEndTime = new Date().getTime();
        loadingTaskRef.current = getDocument({ data: resp.body, pdfBug: true, verbosity: 0 });

        return loadingTaskRef.current.promise;
      }).
      catch((error) => console.error(`ERROR for ${doc.content_url} : STEP 1. ApiUtil.get : ${error}`)).
      then((pdfjsDocument) => {
        if (!pdfjsDocument) {
          return setDocumentLoadError(true);
        }
        pdfDocumentRef.current = pdfjsDocument;
        const promises = _.range(0, pdfjsDocument.numPages).map((index) => {

          return pdfjsDocument.getPage(index + 1);
        });

        return Promise.all(promises);

      }).
      catch((error) => console.error(`ERROR for ${doc.content_url} : STEP 2 getting pdfDocument : ${error}`)).
      then((pages) => {

        return setPdfPages(pages);
      }).
      catch((error) => console.error(`ERROR for ${doc.content_url} : STEP 3 getting pdfPages : ${error}`)).
      then(() => {
        if (loadingTaskRef.current?.destroyed) {
          return pdfDocumentRef.current.destroy();
        }
        loadingTaskRef.current = null;
      }).
      catch((error) => {
        console.error(`ERROR for ${doc.content_url} : STEP 4 getPdfDoc : ${error}`);
      });
  };

  useEffect(() => {
    getPdfDoc();

    return () => {
      // clean up PDFJS objects - with prefetch, this return block runs for every 3 docs. TODO fix
      pdfDocumentRef.current?.destroy();
      loadingTaskRef.current?.destroy();
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
    <>
      <div id="pdfContainer" style={containerStyle}>
        { isDocumentLoadError ? (
          <DocumentLoadError doc={doc} />
        ) : (
          pdfPages.map((page, index) => (
            <R2PdfPage
              key={`${doc.content_url}-${index}`}
              pageResult={page}
              documentId={doc.id}
              file={doc.content_url}
              pageIndex={index}
              isFileVisible
              scale={scale}
              pdfDocument={pdfDocumentRef.current}
              featureToggles={featureToggles}
              rotation={rotation}
            />
          ))
        )}
      </div>
      <ReaderFooter
        currentPage={currentPage}
        docId={doc.id}
        isDocumentLoadError={isDocumentLoadError}
        numPages={pdfPages.length}
        setCurrentPage={setCurrentPage}
        showPdf={showPdf}
      />
    </>
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
  rotateDeg: PropTypes.string,
  setCurrentPage: PropTypes.func,
  zoomLevel: PropTypes.number,
  isVisible: PropTypes.bool,
  showPdf: PropTypes.func,
  featureToggles: PropTypes.object,
  rotation: PropTypes.number,
  scale: PropTypes.number,
};

export default PdfDocument;
