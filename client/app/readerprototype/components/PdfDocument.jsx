import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { css } from 'glamor';


import * as PDFJS from 'pdfjs-dist';
PDFJS.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.6.347/pdf.worker.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';

const PdfDocument = ({ fileUrl, rotateDeg, setNumPages, zoomLevel }) => {
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);

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
    <div style={{ width: '100%', height: '100%', overflow: 'auto', zoom: `${zoomLevel}%` }} id="pdfContainer">
      {pdfPages.map((page, index) => (
        <Page page={page} rotation={rotateDeg} key={`page-index`} />
      ))}
    </div>
  );
};

PdfDocument.propTypes = {
  fileUrl: PropTypes.string,
  rotateDeg: PropTypes.string,
  setNumPages: PropTypes.func,
  zoomLevel: PropTypes.string
};

export default PdfDocument;
