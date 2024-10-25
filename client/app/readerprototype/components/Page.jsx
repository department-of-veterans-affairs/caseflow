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
const Page = memo(({
  page,
  rotation = ROTATION_DEGREES.ZERO,
  renderItem,
  scale,
  setRenderingMetrics,
  setCurrentPage
}) => {
  const scaleFraction = scale / 100;
  const currentPageFraction = Math.min(0.5 / Math.pow(scaleFraction, 2), 1);
  const canvasRef = useRef(null);
  const isVisibleRef = useRef(null);

  isVisibleRef.current = usePageVisibility(canvasRef);
  const shouldSetCurrentPage = usePageVisibility(canvasRef, currentPageFraction);

  const wrapperRef = useRef(null);
  const renderTaskRef = useRef(null);
  const [previousScale, setPreviousScale] = useState(scale);
  const hasRenderedRef = useRef(false);
  const reportedStatsRef = useRef(false);
  const [isLoading, setIsLoading] = useState(false);

  const viewportRef = useRef(page.getViewport({ scale: scaleFraction }));

  const scaledHeight = viewportRef.current.height;
  const scaledWidth = viewportRef.current.width;
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
    backgroundColor: 'transparent',
  };
  let canvasStyle = {
    rotate: rotation,
    position: 'relative',
    top,
  };

  const render = async () => {
    if (!viewportRef.current) {
      return;
    }
    if (canvasRef.current && isVisibleRef.current && !hasRenderedRef.current) {
      if (renderTaskRef.current) {
        // try to let an existing render task to finish
        try {
          await renderTaskRef.current.cancel();
        } catch {
          // no op when an existing render task fails
        }
      }

      renderTaskRef.current = page.render({
        canvasContext: canvasRef.current.getContext('2d', { alpha: false }),
        viewport: viewportRef.current,
      });

      try {
        setIsLoading(true);
        await renderTaskRef.current.promise;
        const pageStats = page?._stats;

        if (pageStats && Array.isArray(pageStats.times)) {

          const renderingTimes = pageStats.times.find((time) => time.name === 'Rendering');

          if (!reportedStatsRef.current && renderingTimes) {
            setRenderingMetrics(renderingTimes.end - renderingTimes.start);
            reportedStatsRef.current = true;
          }
        }
        setIsLoading(false);
        hasRenderedRef.current = true;
      } catch {
        // retry when current render task fails
        // render();
      }
    }
  };

  // render when scale changes, the canvas is ready, we haven't rendered, or the page becomes visible
  useEffect(() => {
    render();
  }, [canvasRef.current, hasRenderedRef.current, isVisibleRef.current, viewportRef.current]);

  // cancel any existing render tasks if still running when we unmount
  useEffect(() => {
    return () => {
      renderTaskRef.current?.cancel();
    };
  }, []);

  useEffect(() => {
    if (shouldSetCurrentPage) {
      setCurrentPage(page.pageNumber);
    }

  }, [shouldSetCurrentPage, scale]);

  // previousScale keeps track of the previous value of scale. if scale changes, that will trigger a component
  // rerender. before that happens, we'd normally try to finish the current component render.
  // since we are about to rerender the whole component anyway, short-circuit the current one to improve
  // performance.
  if (previousScale !== scale) {
    setPreviousScale(scale);
    hasRenderedRef.current = false;
    viewportRef.current = page.getViewport({ scale: scale / 100 });
    renderTaskRef.current?.cancel();

    return;
  }

  const showCanvas = !isLoading;

  return (
    <div
      id={`canvasWrapper-${page.pageNumber}`}
      className={`prototype-canvas-wrapper ${isVisibleRef.current ? 'visible-page' : 'invisible-page'}`}
      style={wrapperStyle}
      ref={wrapperRef}
    >
      <canvas
        id={`canvas-${page.pageNumber}`}
        className={`prototype-canvas ${showCanvas ? '' : 'cf-pdf-page-hidden' }`}
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
  setRenderingMetrics: PropTypes.func,
  setCurrentPage: PropTypes.func
};

export default Page;
