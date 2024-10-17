import React, { memo, useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import * as PDFJS from 'pdfjs-dist';

// Similar to the behavior in Page.jsx, we need to manipulate height and width
// to ensure the container properly handles rotations and keeps the text layer aligned
// with the pdf below it.
const TextLayer = memo((props) => {
  const { page, zoomLevel, rotation } = props;

  // We need to prevent multiple renderings of text to prevent doubling up. Without
  // tracking this, the search bar will report double the number of found instances
  const [hasRenderedText, setHasRenderedText] = useState(false);
  const scale = zoomLevel / 100;
  const viewport = page.getViewport({ scale: 1 });
  const textLayerRef = useRef(null);
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
    const getPageText = async () => {
      page.
        getTextContent().
        then((pageText) => {
          PDFJS.renderTextLayer({
            textContent: pageText,
            container: textLayerRef.current,
            viewport,
            textDivs: [],
          });
          setHasRenderedText(true);
        }).
        catch((error) => {
          // this catch is necessary to prevent the error: TypeError: Cannot read properties of null
          // (reading 'ownerDocument')
          console.error(`text layer ${error}`);
        });
    };

    if (textLayerRef.current && !hasRenderedText) {
      getPageText();
    }
  }, [textLayerRef.current]);

  return <div ref={textLayerRef} className="cf-pdf-pdfjs-textLayer" style={textLayerStyle} />;
});

TextLayer.propTypes = {
  page: PropTypes.any,
  zoomLevel: PropTypes.number,
  rotation: PropTypes.string,
};

export default TextLayer;
