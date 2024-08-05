import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useEffect, useState, useRef } from 'react';
import Layer from './Comments/Layer';
import { useHistory } from 'react-router-dom';

import * as PDFJS from 'pdfjs-dist';
PDFJS.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.6.347/pdf.worker.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import ProgressBar from './ProgressBar';

const PdfDocument = ({ fileUrl, rotateDeg, setNumPages, zoomLevel, documentId, showSideBar }) => {
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);
  const [downloadedBytes, setDownloadedBytes] = useState(0);
  const [totalBytes, setTotalBytes] = useState();
  const xhrRef = useRef(null); // Use ref to keep track of the XMLHttpRequest object
  const history = useHistory();
  const [isDownloadComplete, setIsDownloadComplete] = useState(false);

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
      try {
        const downloadPromise = ApiUtil.downloadWithProgress(fileUrl, ({ loaded, total }) => {
          setDownloadedBytes(loaded);
          setTotalBytes(total);
        });

        xhrRef.current = downloadPromise.xhr;
        // Store the xhr object in the ref for later use

        const byteArr = await downloadPromise;

        const docProxy = await PDFJS.getDocument({ data: byteArr }).promise;

        if (docProxy) {
          setPdfDoc(docProxy);
          setNumPages(docProxy.numPages);
          setIsDownloadComplete(true); // Set the download as complete
        }
      } catch (error) {
        console.error('Error downloading or processing PDF:', error);
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

  const handleCancelDownload = () => {
    if (xhrRef.current) {
      const appealId = window.location.pathname.match(/appeal\/(.*?)\/documents/)[1];
      const redirectUrl = `/${appealId}/documents`;
      console.log('###', redirectUrl)
      xhrRef.current.abort();
      // Abort the download
      history.push(redirectUrl);
      // Redirect to the desired path
    }
  };

  return (
    <div id="pdfContainer" className={containerClass}>
      {!isDownloadComplete && (
        <ProgressBar
          downloadedBytes={downloadedBytes}
          totalBytes={totalBytes}
          onCancel={handleCancelDownload}
          showSideBar={showSideBar}
        />
      )}
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
  showSideBar: PropTypes.bool
};

export default PdfDocument;
