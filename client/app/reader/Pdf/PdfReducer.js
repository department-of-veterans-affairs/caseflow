
import _ from 'lodash';

import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  scrollToComment: null,
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: []
};

export const pdfReducer = (state = initialState, action = {}) => {

  switch (action.type) {
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      scrollToComment: { $set: action.payload.scrollToComment }
    });
  case Constants.SET_UP_PAGE_DIMENSIONS:
  {
    // const t0 = performance.now();
    // update(
    //   state,
    //   {
    //     pageDimensions: {
    //       [`${action.payload.file}-${action.payload.pageIndex}`]: {
    //         $set: {
    //           ...action.payload.dimensions,
    //           file: action.payload.file,
    //           pageIndex: action.payload.pageIndex
    //         }
    //       }
    //     }
    //   }
    // );
    // console.log('updating state', performance.now() - t0);
    // return state;
    const width = _.get(state.pageDimensions, [`${action.payload.file}-${action.payload.pageIndex}`, 'width']);
    const height = _.get(state.pageDimensions, [`${action.payload.file}-${action.payload.pageIndex}`, 'height']);
    // console.log('width', width, action.payload);
    if (width && Math.abs(width - action.payload.dimensions.width) < 5 && height && Math.abs(height - action.payload.dimensions.height) < 5) {
      return state;
    }

    if (!_.filter(state.pageDimensions, (page) => page.file === action.payload.file).length) {
      const pages = _.range(0, action.payload.numPages).reduce((acc, index) => {
        acc[`${action.payload.file}-${index}`] = {
          ...action.payload.dimensions,
          file: action.payload.file,
          pageIndex: index
        };

        return acc;
      }, {});

      return update(
        state,
        {
          pageDimensions: {
            $merge: pages
          }
        }
      );
    }

    return update(
      state,
      {
        pageDimensions: {
          [`${action.payload.file}-${action.payload.pageIndex}`]: {
            $set: {
              ...action.payload.dimensions,
              file: action.payload.file,
              pageIndex: action.payload.pageIndex
            }
          }
        }
      }
    );
  }
  case Constants.SET_PDF_DOCUMENT:
    return update(
      state,
      {
        pdfDocuments: {
          [action.payload.file]: {
            $set: action.payload.doc
          }
        }
      }
    );
  case Constants.CLEAR_PDF_DOCUMENT:
    if (action.payload.doc && _.get(state.pdfDocuments, [action.payload.file]) === action.payload.doc) {
      return update(
        state,
        {
          pdfDocuments: {
            [action.payload.file]: {
              $set: null
            }
          }
        });
    }

    return state;
  case Constants.SET_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: true
        }
      }
    });
  case Constants.CLEAR_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: false
        }
      }
    });
  default:
    return state;
  }
};

export default pdfReducer;
