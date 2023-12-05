import React, { useEffect } from 'react';

const CorrespondencePdfPage = (props) => {
  const { page, scale, rotation, canvasRefs, index, viewportState } = props;

  useEffect(() => {
    const canvas = document.getElementById(`canvas-${page.pageNumber}`);
    const context = canvas.getContext('2d');
    const viewport = page.getViewport({
      scale,
      rotation,
    });

    canvas.width = viewport.width;
    canvas.height = viewport.height;
    viewportState.height = viewport.height;
    viewportState.width = viewport.width;

    const renderOptions = {
      canvasContext: context,
      viewport,
    };

    page.render(renderOptions);
  }, [scale, rotation]);

  return (
    <canvas
      id={`canvas-${page.pageNumber}`}
      className="canvasWrapper"
      ref={(ref) => (canvasRefs.current[index] = ref)} />
  );
};

export default CorrespondencePdfPage;
