/* eslint-disable no-underscore-dangle */
import PropTypes from 'prop-types';
import React, { useEffect, useState, useRef } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/pdfjs/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import DocumentLoadError from './DocumentLoadError';
import { storeMetrics } from '../../util/Metrics';

const PdfDocument = ({ doc, rotateDeg, setNumPages, zoomLevel, onLoad }) => {
  const [isDocumentLoadError, setIsDocumentLoadError] = useState(false);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);
  const getDocumentEnd = useRef(null);
  const getDocumentStart = useRef(null);
  const renderedPageCount = useRef(0);
  const renderedTimeTotal = useRef(0);
  const [allPagesRendered, setAllPagesRendered] = useState(false);
  const [metricsLogged, setMetricsLogged] = useState(false);
  const metricsLoggedRef = useRef(metricsLogged);

  const containerStyle = {
    width: '100%',
    height: '100%',
    overflow: 'auto',
    paddingTop: '10px',
    alignContent: 'start',
    justifyContent: 'center',
    gap: '5rem',
  };

  const handleRenderingMetrics = (renderingTime) => {
    if (renderingTime) {
      renderedTimeTotal.current += renderingTime;
      renderedPageCount.current += 1;
      if (renderedPageCount.current === pdfPages.length && pdfPages.length > 0) {
        setAllPagesRendered(true);
      }
    }
  };

  const getFirstPageOverallTime = () => {
    if (pdfPages && pdfPages.length > 0) {
      const firstPage = pdfPages[0];

      if (firstPage._stats && Array.isArray(firstPage._stats.times)) {
        const overallTime = firstPage._stats.times.find((time) => time.name === 'Overall');

        if (overallTime) {
          return overallTime.end - overallTime.start;
        }
      }
    }

    return 0;
  };

  const logMetrics = () => {
    const calculatedAverage = Math.round(
      renderedPageCount.current > 0 ? renderedTimeTotal.current / renderedPageCount.current : 0
    );

    storeMetrics(
      doc.id,
      {
        document_request_time: getDocumentEnd.current - getDocumentStart.current,
        number_of_pages_rendered: renderedPageCount.current,
        rendering_time_for_allPages: renderedTimeTotal.current,
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

  useEffect(() => {
    const getDocData = async () => {
      renderedPageCount.current = 0;
      renderedTimeTotal.current = 0;
      setPdfDoc(null);
      setPdfPages([]);
      setAllPagesRendered(false);
      setMetricsLogged(false);
      onLoad(true);
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      };

      getDocumentStart.current = new Date().getTime();
      const byteArr = await ApiUtil.get(doc.content_url, requestOptions).then((response) => {
        return response.body;
      });

      getDocumentEnd.current = new Date().getTime();
      onLoad(false);
      const docProxy = await getDocument({ data: byteArr, pdfBug: true }).promise;

      if (docProxy) {
        setPdfDoc(docProxy);
        setNumPages(docProxy.numPages);
      }
    };

    getDocData().catch((error) => {
      console.error(`ERROR with getting doc data: ${error}`);
      setIsDocumentLoadError(true);
    });
  }, [doc.content_url]);

  useEffect(() => {
    const pageArray = [];

    if (!pdfDoc) {
      return;
    }
    const getPdfData = async () => {
      for (let i = 1; i <= pdfDoc.numPages; i++) {
        const page = await pdfDoc.getPage(i);

        pageArray.push(page);
      }
      setPdfPages(pageArray);
    };

    getPdfData();
  }, [pdfDoc]);

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
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`doc-${doc.id}-page-${index}`}
          renderItem={(childProps) => (
            <Layer documentId={doc.id} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
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
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.number,
    type: PropTypes.string,
  }),
  rotateDeg: PropTypes.string,
  setNumPages: PropTypes.func,
  zoomLevel: PropTypes.number,
  onLoad: PropTypes.func,
};

export default PdfDocument;
