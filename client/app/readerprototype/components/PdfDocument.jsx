import PropTypes from 'prop-types';
import React, { useEffect, useRef, useState } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/assets/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import DocumentLoadError from './DocumentLoadError';

const PdfDocument = ({ doc, rotateDeg, setNumPages, zoomLevel }) => {
  const [isDocumentLoadError, setIsDocumentLoadError] = useState(false);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);
  const metricsRef = useRef({});
  const [hasSentMetrics, setHasSentMetrics] = useState(false);

  const containerStyle = {
    width: '100%',
    height: '100%',
    overflow: 'auto',
    paddingTop: '10px',
    alignContent: 'start',
    justifyContent: 'center',
    gap: '5rem',
  };

  const sendMetrics = (metrics) => {
    if (hasSentMetrics) return;
    setHasSentMetrics(true);
    for (const [page, values] of Object.entries(metrics)) {
      console.log(page);
      values
        .filter((value) => value.name === 'Overall')
        .forEach((metric) => {
          console.log(metric.name, (metric.end - metric.start) / 1000);
        });
    }
  };

  // this function is called per page. only actually send the metrics if all pages have loaded
  const storeMetric = (pageNumber, data) => {
    if (hasSentMetrics) return;
    if (metricsRef.current[pageNumber]) return;

    metricsRef.current[pageNumber] = data;

    const totalStored = Object.keys(metricsRef.current).length;

    if (totalStored > 0 && totalStored === pdfPages.length) sendMetrics(metricsRef.current);
  };

  useEffect(() => {
    const getDocData = async () => {
      setPdfDoc(null);
      setPdfPages([]);
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      };
      const byteArr = await ApiUtil.get(doc.content_url, requestOptions).then((response) => {
        return response.body;
      });
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

  // handle the case where the user navigates away from the page before all pages have loaded
  useEffect(() => {
    return () => {
      if (!hasSentMetrics && Object.keys(metricsRef.current).length > 0) {
        console.log('unmount', hasSentMetrics);
        sendMetrics(metricsRef.current);
      }
    };
  });

  return (
    <div id="pdfContainer" style={containerStyle}>
      {isDocumentLoadError && <DocumentLoadError doc={doc} />}
      {pdfPages.map((page, index) => (
        <Page
          storeMetric={storeMetric}
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`page-${index}`}
          renderItem={(childProps) => (
            <Layer documentId={doc.id} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
              <TextLayer page={page} zoomLevel={zoomLevel} rotation={rotateDeg} />
            </Layer>
          )}
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
};

export default PdfDocument;
