import React, { useEffect, useMemo, useRef } from 'react';
import * as pdfjs from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
import { v4 as uuidv4 } from 'uuid';
import CorrespondencePdfPage from './CorrespondencePdfPage';

pdfjs.GlobalWorkerOptions.workerSrc = pdfjsWorker;

const CorrespondencePdfDocument = (props) => {
  const {
    scale,
    pdfPageProxies,
    canvasRefs,
    currentPage,
    setCurrentPage,
    viewport,
    gridRef,
    pdfDocProxy,
    scrollViewRef
  } = props;



  const handleScroll = () => {
    const scrolledHeight = scrollViewRef.current.scrollTop;
    const pageOffset = Math.floor(scrolledHeight / viewport.height);
    const pageNumber = pageOffset + 1;
    setCurrentPage(pageNumber)
  };

  const generatePdfPages = useMemo(() => pdfPageProxies.map((page, index) => {
    return (
      <CorrespondencePdfPage
        key={uuidv4()}
        uuid={uuidv4()}
        canvasRefs={canvasRefs}
        page={page}
        index={index}
        scale={scale}
        viewportState={viewport}
      />
    );
  }, [pdfPageProxies]));

  return (
    <div className="cf-pdf-preview-scrollview" ref={scrollViewRef} onScroll={handleScroll}>
      <div className="cf-pdf-preview-grid" ref={gridRef}>
        { generatePdfPages }
      </div>
    </div>
  );
};

export default CorrespondencePdfDocument;
