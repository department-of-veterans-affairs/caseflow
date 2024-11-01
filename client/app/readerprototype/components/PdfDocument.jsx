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
import _ from 'lodash';
import { PAGE_DIMENSION_SCALE } from '../../reader/constants';

let loadingTask = null;
// let pdfDocument = null;
let pdfDocumentPages = [];

const PdfDocument = ({
  currentPage,
  doc,
  isDocumentLoadError,
  rotateDeg,
  setIsDocumentLoadError,
  setNumPages,
  setCurrentPage,
  isVisible,
  zoomLevel }) => {

    if (!isVisible) {
      return null;
    }

  const loadingTaskRef = useRef(null);
  const pdfDocumentRef = useRef(null);

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

  const getPagesPromise = () => {
    const promises = _.range(0, pdfDoc?.numPages).map((index) => {

      return pdfDoc.getPage(index + 1);
    });

    console.log(`getPagesPromise() for ${doc.content_url} : ${promises}`);
    return Promise.all(promises);
  };

  const getPdfDoc = () => {
    // console.log(`\n\n\n\n======== START getPdfDoc()============= for ${doc.content_url} | pdfDocument: ${pdfDocument}`);
    // console.log(pdfDocument);

    console.log(`======== START getPdfDoc()============= for ${doc.content_url} | pdfDoc: ${pdfDoc}\n\n\n`);
    console.log(pdfDoc);
    // console.log(`getPdfDoc() for ${doc.content_url} | loadingTask: ${loadingTask}`);

    // if (pdfDocument) {
    //   console.log(`\n\n\n\n======== START there IS pdfDocument! delete it!============= for ${doc.content_url} | pdfDocument: ${pdfDocument}`);
    //   pdfDocument.destroy(); //this is for the previous pdfDocument after switching docs
    //   console.log(`\n\n\n\n======== START there IS pdfDocument! make sure deleted for ${doc.content_url} | pdfDocument: ${pdfDocument}`);
    // }

    // console.log(`\n\n\n\n======== START AFTER getPdfDoc()============= for ${doc.content_url} | pdfDocument: ${pdfDocument}`);
    // console.log(pdfDocument)
    // loadingTask = null;
    // pdfDocument = null;
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

    return ApiUtil.get(doc.content_url, requestOptions).
      then((resp) => {
        pdfMetrics.current.getEndTime = new Date().getTime();
        loadingTask = getDocument({ data: resp.body, pdfBug: true, verbosity: 0 });

        return loadingTask.promise;

      }).catch((e) => {
        console.log(`READERLOG ERROR: DOCID${doc.id} | GET ${doc.content_url} : STEP 1. getDocument : ${e}`)
        return setIsDocumentLoadError(true);
      }).
      then((pdfjsDocument) => {

        console.log(`READERLOG  for ${doc.content_url} fingerprint`, pdfjsDocument._pdfInfo.fingerprint);
        //same exact finger print after switching docs
        //READERLOG  for /document/4/pdf fingerprint 5a7b175a7977a9ca6b66401c0a0dc9a8
        //READERLOG  for /document/1/pdf fingerprint 5e6d82253ffef74f9727dde0167ed600
        //READERLOG  for /document/4/pdf fingerprint 5a7b175a7977a9ca6b66401c0a0dc9a8


        pdfDocumentRef.current = pdfjsDocument;
        // pdfDocument = pdfjsDocument;
        setPdfDoc(pdfjsDocument);
        setNumPages(pdfjsDocument.numPages);
        // debugger;

        const promises = _.range(0, pdfjsDocument.numPages).map((index) => {

          return pdfjsDocument.getPage(index + 1);
        });

        return Promise.all(promises);

      }).catch((e) => console.log(`READERLOG ERROR: DOCID${doc.id} | GET ${doc.content_url} : STEP 2 getting pdfDocument : ${e}`)).
      then((pages) => {
        pdfDocumentPages = pages;

        return setPdfPages(pages);
      }).catch((e) => console.log(`READERLOG ERROR: DOCID${doc.id} | GET ${doc.content_url} : STEP 3 getting pdfPages : ${e}`)).
      then(() => {

        console.log(`getPdfDoc()====cleanup========= for ${doc.content_url} | pdfDoc: ${pdfDoc}`);
        //get rid of this block? if theres clean up in useEffect return
        if (loadingTask?.destroyed) {
          // debugger;
          return pdfDocumentRef.current.destroy();
        }
        loadingTask = null;
      }).catch((e) => console.log(`READERLOG ERROR: DOCID${doc.id} | GET ${doc.content_url} : STEP 3 getting pdfPages : ${e}`));
      // loadingTask?.destroy();
      // pdfDocument?.destroy();
      // loadingTask = null;
      // pdfDocument = null;
  };

  useEffect(() => {
    getPdfDoc();

    return () => {
      // loadingTask?.destroy();

      console.log(`\n\n\nREADERLOG********* CLEANUP() for ${doc.content_url} pdfDocumentRef`, pdfDocumentRef.current);
      pdfDocumentRef.current?.destroy();
      // debugger;
      console.log(`READERLOG********* CLEANUP() for ${doc.content_url} pdfDocumentRef`, pdfDocumentRef.current);


      // pdfDocument?.destroy();
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
      {/* {isDocumentLoadError && <DocumentLoadError doc={doc} />} */}
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
  isVisible: PropTypes.bool,
};

export default PdfDocument;
