import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as PDFJS from 'pdfjs-dist';

const TextLayer = (props) => {
  const { page } = props;
  const viewport = page.getViewport({ scale: 1 });
  const textLayerRef = useRef(null);

  const textLayerStyle = css({
    width: `${viewport?.width}px`,
    height: `${viewport?.height}px`,
    transformOrigin: 'left top',
    opacity: 1,
    position: 'absolute',
    top: '10px',
    left: '10px',
  });

  useEffect(() => {
    const getPageText = async () => {
      const pageText = await page.getTextContent();

      PDFJS.renderTextLayer({
        textContent: pageText,
        container: textLayerRef.current,
        viewport,
        textDivs: [],
      });
    };

    if (textLayerRef.current) {
      getPageText();
    }
  }, [textLayerRef.current]);

  return <div ref={textLayerRef} className={`cf-pdf-pdfjs-textLayer ${textLayerStyle}`} />;
};

TextLayer.propTypes = {
  page: PropTypes.any,
};

export default TextLayer;
