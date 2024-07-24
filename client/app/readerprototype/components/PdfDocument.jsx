import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import Layer from './Comments/Layer';

import * as PDFJS from 'pdfjs-dist';
PDFJS.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.6.347/pdf.worker.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';

const PdfDocument = ({ fileUrl, rotateDeg, setNumPages, zoomLevel, documentId }) => {
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);

  const containerClass = css({
    width: '100%',
    height: '100%',
    overflow: 'auto',
    alignContent: 'start',
    flexGrow: 'auto',
    zoom: `${zoomLevel}%`,
    justifyContent: 'center',
    gap: zoomLevel > 100 ? `${zoomLevel / 3}rem 15rem` : 0,
  });

  useEffect(() => {
    const getDocData = async () => {
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      };
      const byteArr = await ApiUtil.get(fileUrl, requestOptions).then((response) => {
        return response.body;
      });
      const docProxy = await PDFJS.getDocument({ data: byteArr }).promise;

      if (docProxy) {
        setPdfDoc(docProxy);
        setNumPages(docProxy.numPages);
      }
    };

    getDocData();
  }, [fileUrl]);

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

  return (
    <div id="pdfContainer" className={containerClass}>
      {pdfPages.map((page, index) => (
        <Page
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`page-${index}`}
          renderItem={(childProps) => (
            <Layer documentId={documentId} zoomLevel={zoomLevel} {...childProps}>
              <TextLayer page={page} />
            </Layer>
          )}
        />
      ))}
    </div>
  );
};

PdfDocument.propTypes = {
  fileUrl: PropTypes.string,
  rotateDeg: PropTypes.string,
  setNumPages: PropTypes.func,
  zoomLevel: PropTypes.number,
  documentId: PropTypes.number,
};

export default PdfDocument;
