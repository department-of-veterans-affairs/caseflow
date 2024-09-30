import PropTypes from 'prop-types';
import React, { memo, useEffect, useRef, useState } from 'react';
import usePageVisibility from '../hooks/usePageVisibility';
import { ROTATION_DEGREES } from '../util/readerConstants';

// This Page component is expected to be used within a flexbox container. Flex doesn't notice when children are
// transformed (scaled and rotated). Where * is the flex container:
//      *|--------------|*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|--------------|*
//
// When rotated and scaled looks like this:
//      *                *
//      *                *
//      *                *
//      *    --------    *
//      *    |      |    *
//      *    ________    *
//      *                *
//      *                *
// We have to also change the dimensions of the container so that the flex reflows.
// When scaling, we multiply the height and width (via the getViewport call) by the scale.
// When rotating, we swap height and width of the container.
// The child is still centered in the container, so we must offset it put it back to the
// top / center of the container.
const Page = memo(({ page, rotation = ROTATION_DEGREES.ZERO, renderItem, scale }) => {
  const canvasRef = useRef(null);
  const isVisible = usePageVisibility(canvasRef);
  const wrapperRef = useRef(null);
  const renderTimeout = useRef(null);
  const [previousScale, setPreviousScale] = useState(scale);
  const [hasRendered, setHasRendered] = useState(false);

  const scaleFraction = scale / 100;
  const viewport = page.getViewport({ scale: scaleFraction });
  const scaledHeight = viewport.height;
  const scaledWidth = viewport.width;
  let rotatedHeight = scaledHeight;
  let rotatedWidth = scaledWidth;
  let top = 0;
  let left = 0;
  const offset = (scaledHeight - scaledWidth) / 2;

  if (rotation.includes('90') || rotation.includes('270')) {
    rotatedHeight = scaledWidth;
    rotatedWidth = scaledHeight;
    top = `${offset * -1}px`;
    left = `${offset}px`;
  }
  const wrapperStyle = {
    height: `${rotatedHeight}px`,
    width: `${rotatedWidth}px`,
    position: 'relative',
    backgroundColor: 'white',
  };
  let canvasStyle = {
    rotate: rotation,
    position: 'relative',
    top,
    // removes offscreen canvas from rendering calculations to improve performance
    contentVisibility: 'auto',
  };

  const render = () => {
    if (canvasRef.current && isVisible && !hasRendered) {
      const task = page.render({ canvasContext: canvasRef.current.getContext('2d', { alpha: false }), viewport });

      task.promise.then(() => {
        if (scale === previousScale) {
          setHasRendered(true);
        } else {
          // if the scale has changed while this was processing, render it again
          clearTimeout(renderTimeout.current);
          renderTimeout.current = setTimeout(render, 0);

        }
      }).catch(() => {
        clearTimeout(renderTimeout.current);
        renderTimeout.current = setTimeout(render, 0);
      });
    }
  };

  // render immediately when the canvas ref is ready
  useEffect(() => {
    clearTimeout(renderTimeout.current);
    renderTimeout.current = setTimeout(render, 0);
  }, [canvasRef.current]);

  // render when the page becomes visible. only do it the first time at this zoom level
  // so that scrolling doesn't trigger rerenders
  useEffect(() => {
    if (isVisible) {
      clearTimeout(renderTimeout.current);
      renderTimeout.current = setTimeout(render, 500);
    }

  }, [isVisible]);

  // render when hasRendered has been reset to false. if the page isn't visible, the render
  // function ignores the render request
  useEffect(() => {
    if (!hasRendered) {
      clearTimeout(renderTimeout.current);
      renderTimeout.current = setTimeout(render, 0);
    }
  }, [hasRendered]);

  // as we zoom in and out, we need to re-render
  useEffect(() => {
    clearTimeout(renderTimeout.current);
    renderTimeout.current = setTimeout(render, 1000);
  }, [scale, previousScale]);

  // clean up the timeout if we navigate away
  useEffect(() => {
    return () => {
      clearTimeout(renderTimeout.current);
    };
  }, []);

  // previousScale keeps track of the previous value of scale. if scale changes, that will trigger a component
  // rerender. before that happens, we'd normally try to finish the current component render.
  // since we are about to rerender the whole component anyway, short-circuit the current one to improve
  // performance.
  if (previousScale !== scale) {
    setPreviousScale(scale);
    setHasRendered(false);

    return;
  }

  const hideCanvas = !hasRendered || scale !== previousScale;

  return (
    <div
      id={`canvasWrapper-${page.pageNumber}`}
      className="prototype-canvas-wrapper"
      style={wrapperStyle}
      ref={wrapperRef}
    >
      <canvas
        id={`canvas-${page.pageNumber}`}
        className={`prototype-canvas ${hideCanvas ? 'cf-pdf-page-hidden' : '' }`}
        style={canvasStyle}
        ref={canvasRef}
        height={scaledHeight}
        width={scaledWidth}
      />
      {renderItem &&
        renderItem({
          pageNumber: page.pageNumber,
          dimensions: {
            height: scaledHeight,
            width: scaledWidth,
            offsetX: left,
            offsetY: top,
          },
          rotation,
        })}
    </div>
  );
});

Page.propTypes = {
  page: PropTypes.object,
  rotation: PropTypes.string,
  renderItem: PropTypes.func,
  scale: PropTypes.number,
};

export default Page;
