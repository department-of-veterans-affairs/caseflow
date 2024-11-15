import Mark from 'mark.js';
import * as PDFJS from 'pdfjs-dist';
import PropTypes from 'prop-types';
import React, { memo, useEffect, useRef, useState } from 'react';
import { useSelector } from 'react-redux';
import { getRelativeIndex, getSearchTerm } from '../../reader/selectors';
import usePageVisibility from '../hooks/usePageVisibility';

const isMarkOnScreen = (mark) => {
  const { top: markTop, bottom: markBottom } = mark.getBoundingClientRect();
  const { top: containerTop, bottom: containerBottom } = document.getElementById('pdfContainer').getBoundingClientRect();

  console.log(markTop, markBottom, containerTop, containerBottom);
  if ((markTop - 100) > containerTop && (markBottom + 200) < containerBottom) {
    return true;
  }

  return false;
};
// Similar to the behavior in Page.jsx, we need to manipulate height and width
// to ensure the container properly handles rotations and keeps the text layer aligned
// with the pdf below it.
const TextLayer = memo((props) => {
  const { viewport, textContent, zoomLevel, rotation, hasSearchMatch, pnum } = props;
  const relativeIndex = useSelector(getRelativeIndex);
  const textLayerRef = useRef(null);
  const isVisible = usePageVisibility(textLayerRef);
  const markInstanceRef = useRef(null);
  // We need to prevent multiple renderings of text to prevent doubling up. Without
  // tracking this, the search bar will report double the number of found instances
  const [hasRenderedText, setHasRenderedText] = useState(false);
  const searchTerm = useSelector(getSearchTerm);
  const scale = zoomLevel / 100;

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
    const renderText = async () => {
      // render the text into the page if that page is either visible or if it has search results on it.
      if (textLayerRef.current && textContent && !hasRenderedText && (isVisible || hasSearchMatch)) {
        await PDFJS.renderTextLayer({
          textContent,
          container: textLayerRef.current,
          viewport,
          textDivs: [],
        });

        setHasRenderedText(true);
      }
    };

    renderText();
  }, [textLayerRef.current, textContent, hasRenderedText, isVisible, hasSearchMatch]);

  useEffect(() => {
    if (hasRenderedText && searchTerm) {
      if (!markInstanceRef.current) {
        markInstanceRef.current = new Mark(textLayerRef.current);
      }
      const markInstance = markInstanceRef.current;

      markInstance.unmark();
      markInstance.mark(searchTerm, {
        separateWordSearch: false,
        done: () => {
          const marks = textLayerRef.current.getElementsByTagName('mark');

          marks.forEach((mark, index) => {
            mark.classList.remove('highlighted');

            if (index === relativeIndex && hasSearchMatch) {
              mark.classList.add('highlighted');
              if (!isMarkOnScreen(mark)) {
                mark.scrollIntoView({ block: 'center' });
              }
            }
          });
        }
      });
    }
  }, [hasRenderedText, searchTerm, relativeIndex, hasSearchMatch]);

  return (
    <div
      ref={textLayerRef}
      className="cf-pdf-pdfjs-textLayer"
      style={textLayerStyle}
    />
  );
});

TextLayer.propTypes = {
  textContent: PropTypes.object,
  zoomLevel: PropTypes.number,
  rotation: PropTypes.string,
  viewport: PropTypes.object,
  hasSearchMatch: PropTypes.bool
};

export default TextLayer;
