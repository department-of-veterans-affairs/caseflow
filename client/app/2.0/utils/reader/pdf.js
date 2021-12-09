// External Dependencies
import * as PDF from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
import { isEmpty, range } from 'lodash';

import ApiUtil from 'app/util/ApiUtil';
import { DEFAULT_VIEWPORT } from 'store/constants/reader';

// Set the PDFJS service worker
PDF.GlobalWorkerOptions.workerSrc = pdfjsWorker;

const PROGRESS_INCREMENT = 20;

export const updateProgress = (current, index, sectionLength) => {
  let increment = current;

  if (index !== null) {
    increment += (PROGRESS_INCREMENT / (index / sectionLength));
  }

  if (increment < 100) {
    document.getElementById('progress-bar-container').style.width = `${increment}%`;
    document.getElementById('progress-bar-content').innerHTML = `${increment}%`;
  } else {
    document.getElementsByClassName('cf-pdf-scroll-view')[0].style.marginTop = 0;
  }

  return increment;
};

export const renderAllText = async ({ pdf }) => {
  const getTextForPage = (index) => pdf.getPage(index + 1).then((page) => page.getTextContent());
  const getTextPromises = range(pdf.numPages).map((index) => getTextForPage(index));

  const pages = await Promise.all(getTextPromises);
  const textObject = pages.reduce((acc, page, pageIndex) => {
    // PDFJS textObjects have an array of items. Each item has a str.
    // Concatenating all of these gets us to the page text.
    const concatenated = page.items.map((row) => row.str).join(' ');

    return {
      ...acc,
      [`${pdf}-${pageIndex}`]: {
        id: `${pdf}-${pageIndex}`,
        text: concatenated,
        pageIndex
      }
    };
  }, {});

  // // Create the list of text layer containers
  // const layers = [];

  // const pages = await Promise.all(range(pdf.numPages).map((index) => pdf._transport.getPage(index + 1)));

  // // Map the Extract to promises
  // const textPromises = pages.map((page) => page.getTextContent());
  // const renderPromises = pages.map((page, index) => new Promise((resolve, reject) => {
  //   const error = renderPage({
  //     scale,
  //     index,
  //     page,
  //     docId: pdf.id,
  //     setRenderError: reject
  //   });

  //   if (!error) {
  //     resolve();
  //   }
  // }));

  // // Wait for the search to complete
  // await Promise.all(renderPromises);
  // const text = await Promise.all(textPromises);

  // // Render the text layer
  // const pageList = text.map((textContent, index) => {
  //   // Retrieve the text layer element
  //   layers[index] = document.getElementById(`text-${index}`);

  //   // Reset the container contents if present
  //   if (layers[index]) {
  //     layers[index].innerHTML = '';
  //   }

  //   return PDF.renderTextLayer({
  //     textContent,
  //     container: layers[index],
  //     viewport: pdf.viewport,
  //     textDivs: [],
  //   }).promise;
  // });

  // // Resolve all of the text rendering
  // await Promise.all(pageList);
};

export const search = ({ searchTerm, numPages, matchIndex, pdfId }) => {
  const layers = range(numPages).map((index) => document.getElementById(`text-${index}`));

  // Create the Regex Match
  const regex = new RegExp(
    searchTerm ? searchTerm.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&') : null,
    'gi'
  );

  // Calculate the Search Matches
  const match = (page) =>
    (
      page.items.
        map((row) => row.str).
        join(' ').
        match(regex) || []
    ).length;

  // Reduce the Pages to an object containing the matches
  // const matches = pages.reduce((count, page) => count + match(page), 0);
};

/**
 * Render a Page from the PDF
 * @param {Object} props -- Page properties
 */
export const renderPage = async ({ page, index, docId, scale, setRenderError }) => {
  try {
    if (isEmpty(page)) {
      return;
    }
    // updateProgress(PROGRESS_INCREMENT, index, 2);

    // Get the canvas and calculate the viewport size
    const viewport = page ? page.getViewport({ scale }) : DEFAULT_VIEWPORT;
    const canvas = document.getElementById(`pdf-canvas-${docId}-${index}`);

    // Change the canvas height and width to match the viewport
    canvas.height = viewport.height;
    canvas.width = viewport.width;

    // Render the page to the canvas
    page.render({ canvasContext: canvas.getContext('2d', { alpha: false }), viewport });
  } catch (error) {
    console.error(error);
    setRenderError(true);
  }
};

/**
 * Render Page Text from the PDF to the DOM
 * @param {Object} props -- Page props to get the text content
 */
export const renderText = async ({ page, pageIndex, scale, totalPages, setRenderError }) => {
  try {
    if (isEmpty(page)) {
      return;
    }
    // updateProgress(PROGRESS_INCREMENT * 3, pageIndex, 2);
    // Get the DOM element and text content to be rendered
    const textContent = await page.getTextContent();
    const container = document.getElementById(`text-${pageIndex}`);

    // Render the text layer to the DOM
    await PDF.renderTextLayer({ container, textContent, viewport: page.getViewport({ scale }), textDivs: [] }).promise;

    if (pageIndex === totalPages) {
      document.dispatchEvent(new Event('renderComplete'));
    }
  } catch (error) {
    setRenderError(true);
  }
};

/**
 * Render the PDF file to the DOM
 * @param {Object} props -- PDF props to get and set the pages
 */
export const renderPdf = async ({ pdf, setPages, setRenderError }) => {
  try {
    if (isEmpty(pdf)) {
      return;
    }
    document.dispatchEvent(new Event('rendering'));

    // updateProgress(PROGRESS_INCREMENT, null);
    // Store the pages for the PDF
    const pages = await Promise.all(range(0, pdf.numPages).map((pageIndex) => pdf.getPage(pageIndex + 1)));

    setPages(pages);
  } catch (error) {
    setRenderError(true);
  }
};

export const renderContent = ({ page, docId, scale, pageIndex, totalPages, setRenderError }) => {
  renderPage({ page, docId, scale, index: pageIndex, totalPages, setRenderError });
  renderText({ page, pageIndex, scale, totalPages, setRenderError });
};

/**
 * Retrieve the PDF contents from Storage
 * @param {Object} props -- PDF Metadata and methods to handle caching PDF files
 */
export const fetchPdf = async ({ cache, pdfMeta, updateCache }) => {
  try {
    // Escape if the document is not available yet
    if (!pdfMeta) {
      return;
    }

    // Request the PDF document from eFolder
    if (!cache[pdfMeta.id]) {
      const { body } = await ApiUtil.get(pdfMeta.content_url, {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      });

      // Store the Document in-memory so that we do not serialize through Redux, but still persist
      const pdf = PDF.getDocument({ data: body });

      cache[pdfMeta.id] = await pdf.promise;
    }

    // Cache the updates to the PDF documents
    updateCache(cache);

    // Return the new Document state
    return {
      ...pdfMeta,
      ...cache[pdfMeta.id],
      numPages: cache[pdfMeta.id]._pdfInfo.numPages,
      rotation: 0,
      currentPage: 1,
    };
  } catch (error) {
    return error;
  }
};

/**
 * Wrapper to load the PDF content and handle any errors
 * @param {Object} props -- Caching and error handling for the PDF
 */
export const loadContent = ({ cache, pdfMeta, setPdf, setLoadError, updateCache }) => {
  fetchPdf({ cache, pdfMeta, scale: 1, updateCache }).then((content) => {
    if (content === false) {
      return setLoadError(true);
    }

    return setPdf(content);
  });
};
