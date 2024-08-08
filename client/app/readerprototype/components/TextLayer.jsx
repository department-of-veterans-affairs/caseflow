import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import * as PDFJS from 'pdfjs-dist';

const TextLayer = (props) => {
  const { page, zoomLevel, rotation } = props;

  const [hasRenderedText, setHasRenderedText] = useState(false);

  const viewport = page.getViewport({ scale: zoomLevel / 100 });
  const textLayerRef = useRef(null);
  let positionX = 0;
  let positionY = 0;
  const fullSizeViewport = page.getViewport({ scale: 1 });

  if (rotation.includes('90')) positionX = viewport.height;
  if (rotation.includes('180')) {
    positionX = viewport.width;
    positionY = viewport.height;
  }
  if (rotation.includes('270')) positionY = viewport.width;

  const textLayerStyle = {
    width: `${fullSizeViewport.width}px`,
    height: `${fullSizeViewport.height}px`,
    transformOrigin: 'left top',
    opacity: 1,
    position: 'absolute',
    top: `${positionY}px`,
    left: `${positionX}px`,
    rotate: rotation,
    transform: `scale(${zoomLevel / 100})`,
  };

  useEffect(() => {
    const getPageText = async () => {
      const pageText = await page.getTextContent();

      PDFJS.renderTextLayer({
        textContent: pageText,
        container: textLayerRef.current,
        viewport,
        textDivs: [],
      });
      setHasRenderedText(true);
    };

    if (textLayerRef.current && !hasRenderedText) {
      getPageText();
    }
  }, [textLayerRef.current]);

  return <div ref={textLayerRef} className="cf-pdf-pdfjs-textLayer" style={textLayerStyle} />;
};

TextLayer.propTypes = {
  page: PropTypes.any,
  zoomLevel: PropTypes.number,
  rotation: PropTypes.string,
};

export default TextLayer;
