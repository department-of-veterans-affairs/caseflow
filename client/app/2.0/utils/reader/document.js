// External Dependencies
import { orderBy, sortBy, isEmpty, range } from 'lodash';

// Local Dependencies
import { loadDocuments } from 'store/reader/documentList';
import {
  documentCategories,
  DOCUMENTS_OR_COMMENTS_ENUM,
  CATEGORIES,
  PDF_PAGE_WIDTH,
  PDF_PAGE_HEIGHT,
  PAGE_MARGIN
} from 'store/constants/reader';
import { formatCategoryName, formatFilterCriteria, searchString } from 'utils/reader';
import { fetchAppealDetails } from 'store/reader/appeal';
import { navigate } from 'store/routes';

/*
 * Helper Method to load documents into the store only when necessary
 * @param {string} loadedId -- Id of the Appeal in the Store
 * @param {string} vacolsId -- The New Appeal ID
 */
export const fetchDocuments = ({ appeal, params }, dispatch) => () => {
  // Set the crumbs for the Reader app
  const crumbs = [{
    breadcrumb: 'Reader',
    path: '/reader/appeal/:vacolsId/documents'
  }];

  // Update the crumbs if navigating to a document
  if (params.docId) {
    crumbs.push({
      breadcrumb: 'Document Viewer',
      path: '/reader/appeal/:vacolsId/documents/:docId'
    });
  }

  // Load the crumbs into the navbar
  dispatch(navigate({ crumbs }));

  // Load the Data Needed by the Documents List
  if (appeal.id !== params.vacolsId) {
    // Load the new Documents
    dispatch(loadDocuments(params));
  }

  // Determine whether to load the appeal details
  if (isEmpty(appeal) || ((appeal.vacols_id || appeal.external_id) !== params.vacolsId)) {
    dispatch(fetchAppealDetails(params.vacolsId));
  }
};

/**
 * Helper Method to Calculate the Documents List View
 * @param {array} documents -- List of documents for the selected appeal
 * @param {Object} filter -- The Document Filter Criteria
 * @param {string} view -- The Currently selected view
 * @returns {string} -- The type of view to load in the documents list
 */
export const documentsView = (documents, filter, view) => {
  // Return no Results if there are no documents found matching the search
  if (!documents.length && filter.searchQuery.length > 0) {
    return 'none';
  }

  // Set the Comments view if viewing the Comments table
  if (view === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS) {
    return 'comments';
  }

  // Default to return the documents table
  return 'documents';
};

/**
 * Helper Method to Calculate the Document Rows
 * @param {array} documents -- The list of documents for the selected appeal
 * @param {array} annotationsPerDocument -- The list of comments for each document
 * @returns {array} -- The list of comment rows for the table
 */
export const documentRows = (ids, documents, annotations) => ids.reduce((acc, id) => {
  // Add the current document
  acc.push(documents[id]);

  // Get the documents with comments
  const [docWithComments] = annotations.filter((note) => note.document_id === id);

  // Apply the comment if present
  if (docWithComments && documents[id].listComments) {
    // Add the comment to the list
    acc.push({ ...documents[id], isComment: true });
  }

  // Default to return the document
  return acc;
}, []);

/**
 * Helper Method to download the document
 * @param {string} contentUrl -- The absolute path to the document
 * @param {string} type -- The type of document
 */
export const openDownloadLink = (contentUrl, type) => {
  // Update the windows analytics with the action
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');

  // Trigger the file download
  window.open(`${contentUrl}?type=${type}&download=true`);
};

/**
 * Helper Method to get the page number by page index
 * @param {number} index -- The index of the current page
 */
export const pageNumber = (index) => index + 1;

/**
 * Helper Method to get the index number by page number
 * @param {number} number -- The number of the current page
 */
export const pageIndex = (number) => number - 1;

/**
 * Helper Method to translate the rotation into X coordinates
 * @param {number} rotation -- The current document rotation
 * @param {number} outerHeight -- The height of the containing element
 * @param {number} outerWidth -- The width of the containing element
 */
export const translateX = (rotation, outerHeight, outerWidth) =>
  Math.sin((rotation / 180) * Math.PI) * (outerHeight - outerWidth) / 2;

/**
 * Helper Method to count the number of columns for a specific page
 * @param {number} width -- The Width of the screen
 * @param {number} pageWidth -- The Width of the page
 * @param {number} numPages -- The number of pages
 */
export const columnCount = (width, pageWidth, numPages) =>
  Math.min(Math.max(Math.floor(width / pageWidth), 1), numPages);

/**
 * Helper Method to filter documents based on criteria object
 * @param {Object} criteria -- The criteria to filter on
 * @param {Object} documents -- The list of documents
 * @returns {array} -- Contains the IDs of the filtered documents
 */
export const filterDocuments = (criteria, documents, state) => {
  // Get the Filters to apply
  const { active, filters } = formatFilterCriteria(criteria);

  // Set the Original Documents according to the initial state
  const docs = Object.values(state.storeDocuments ? state.storeDocuments : documents);
  const sortedDocs = orderBy(docs, [criteria.sort.sortBy], criteria.sort.sortAscending ? ['asc'] : ['desc']);

  return active.length ?
    sortedDocs.filter((document) => {
      // Initialize whether to show the document
      let include = true;

      // Apply the Category filters
      if (!isEmpty(filters.category)) {
        include = include && filters.category.filter((name) => document[name] === true).length;
      }

      // Apply the Tag filters
      if (!isEmpty(filters.tag)) {
        include = include && document?.tags?.some((tag) => filters.tag.includes(tag.text));
      }

      // Apply the search filters
      if (filters.searchQuery) {
        include = include && searchString(filters.searchQuery, state)(document);
      }

      // Default return the object to be truthy
      return include;
    }).map((doc) => doc.id) :
    sortedDocs.map((doc) => doc.id);
};

export const rowHeight = ({ numPages, dimensions, horizontal }) => {
  // Return the default width if there are no pages yet
  if (!numPages) {
    return PDF_PAGE_HEIGHT;
  }

  // Get the list of page heights
  const heights = range(0, numPages).map(() => {
    // Return the page width if Horizontal
    if (horizontal) {
      return dimensions?.width || PDF_PAGE_WIDTH;
    }

    // Default to return the page height
    return dimensions?.height || PDF_PAGE_HEIGHT;
  });

  // Return the Max height of the pages as the row height
  return (Math.max(...heights) + PAGE_MARGIN);
};

export const columnWidth = ({ numPages, dimensions, horizontal }) => {
  // Return the default width if there are no pages yet
  if (!numPages) {
    return PDF_PAGE_WIDTH;
  }

  // Calculate the max width
  const widths = range(0, numPages).map(() => {
    // Default to return the page height
    if (horizontal) {
      return dimensions?.height || PDF_PAGE_HEIGHT;
    }

    // Return the page width if Horizontal
    return dimensions?.width || PDF_PAGE_WIDTH;
  });

  // Return the width based on the current scale
  return (Math.max(...widths) + PAGE_MARGIN);
};
