import * as PDFJS from 'pdfjs-dist';
import PropTypes from 'prop-types';
import React, { memo, useEffect, useRef, useState } from 'react';
import usePageVisibility from '../hooks/usePageVisibility';

// Similar to the behavior in Page.jsx, we need to manipulate height and width
// to ensure the container properly handles rotations and keeps the text layer aligned
// with the pdf below it.
const TextLayer = memo((props) => {
  // isSearching is used to trigger a re-render so that the text layer is searchable for all pages
  // eslint-disable-next-line no-unused-vars
  const { page, zoomLevel, rotation, isSearching } = props;

  // We need to prevent multiple renderings of text to prevent doubling up. Without
  // tracking this, the search bar will report double the number of found instances
  const [hasRenderedText, setHasRenderedText] = useState(false);
  const scale = zoomLevel / 100;
  const viewport = page.getViewport({ scale: 1 });
  const textLayerRef = useRef(null);
  const textContentRef = useRef(null);
  const isVisible = usePageVisibility(textLayerRef);

  let positionX = 0;
  let positionY = 0;

  if (rotation.includes('90')) {
    positionX = viewport.height * scale;
  }
  if (rotation.includes('180')) {
    positionX = viewport.width * scale;
    positionY = viewport.height * scale;
  }
  if (rotation.includes('270')) {
    positionY = viewport.width * scale;
  }

  const textLayerStyle = {
    width: `${viewport.width}px`,
    height: `${viewport.height}px`,
    transformOrigin: 'left top',
    opacity: 1,
    position: 'absolute',
    top: `${positionY}px`,
    left: `${positionX}px`,
    rotate: rotation,
    transform: `scale(${scale})`,
  };

  useEffect(() => {
    const getPageText = () => {
      page.getTextContent().then((result) => {
        textContentRef.current = result;
      });
    };

    if (textLayerRef.current && !textContentRef.current && !hasRenderedText) {
      getPageText();
    }
  }, [textLayerRef.current]);

  useEffect(() => {
    if (textLayerRef.current && textContentRef.current && !hasRenderedText) {
      PDFJS.renderTextLayer({
        textContent: textContentRef.current,
        container: textLayerRef.current,
        viewport,
        textDivs: [],
      });
      setHasRenderedText(true);
    }
  }, [textLayerRef.current, textContentRef.current, hasRenderedText, isVisible]);

  return (
    <div
      ref={textLayerRef}
      className="cf-pdf-pdfjs-textLayer"
      style={textLayerStyle}
    />
  );
});

TextLayer.propTypes = {
  page: PropTypes.any,
  zoomLevel: PropTypes.number,
  rotation: PropTypes.string,
  isSearching: PropTypes.bool
};

export default TextLayer;
