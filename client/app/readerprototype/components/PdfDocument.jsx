import PropTypes from 'prop-types';
import React, { useEffect, useState, useRef } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/assets/pdf.worker.min.js';

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

  useEffect(() => {
    const getDocData = async () => {
      renderedPageCount.current = 0;
      renderedTimeTotal.current = 0;
      setPdfDoc(null);
      setPdfPages([]);
      setAllPagesRendered(false);
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
    if (allPagesRendered) {
      console.log(
        '** Metric\n',
        'Document request time', getDocumentEnd.current - getDocumentStart.current, '\n',
        'Number of pages rendered', renderedPageCount.current, '\n',
        'Rendering Time for all pages', renderedTimeTotal.current, '\n',
        'Average rendering time per Page',
        Math.round(renderedPageCount.current > 0 ? renderedTimeTotal.current / renderedPageCount.current : 0),
        '\n',
        'First page overall time',
        pdfPages[0]._stats.times.find((time) => time.name === 'Rendering').end - pdfPages[0]._stats.times.find((time) => time.name === 'Rendering').start
      );

      const calculatedAverage = Math.round(
        renderedPageCount.current > 0 ? renderedTimeTotal.current / renderedPageCount.current : 0
      );

      storeMetrics(
        doc.id,
        {
          document_request_time: getDocumentEnd.current - getDocumentStart.current,
          number_of_pages_rendered: renderedPageCount.current,
          rendering_time_for_allPages: renderedTimeTotal.current,
          average_rendering_time_per_page: calculatedAverage
        },
        {
          message: 'Reader Prototype times in milliseconds',
          type: 'performance',
          product: 'reader prototype',
          start: null,
          end: null,
          duration: null
        },
        null // event_id not used
      );
    }

    return () => {
      if (!allPagesRendered) {
        console.log('** Component unmounted all pages not rendered');
      }
    };
  }, [allPagesRendered]);

  return (
    <div id="pdfContainer" style={containerStyle}>
      {isDocumentLoadError && <DocumentLoadError doc={doc} />}
      {pdfPages.map((page, index) => (
        <Page
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`page-${index}`}
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
