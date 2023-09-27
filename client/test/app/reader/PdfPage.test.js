import React from 'react';
import { shallow } from 'enzyme';
import sinon from 'sinon';
import rootReducer from '../../../app/reader/reducers';
import { Provider, connect } from 'react-redux';
import { mount } from 'enzyme';
import thunk from 'redux-thunk';
import { createStore, applyMiddleware } from 'redux';
import { documents } from "../../data/documents";
import { recordMetrics, storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';
import ApiUtil from '../../../app/util/ApiUtil';

import PdfPage from '../../../app/reader/PdfPage';

jest.mock('../../../app/util/ApiUtil');

jest.mock('../../../app/util/Metrics', () => ({
  storeMetrics: jest.fn().mockReturnThis(),
  recordMetrics: jest.fn().mockReturnThis(),
  recordAsyncMetrics: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

const featureToggles = {
    metricsPdfStorePages: false,
    pdfPageRenderTimeInMs: false
};

const setUpPdfPage = (store, featureToggles) => {
  const numPages = 3;
  return shallow(
    <Provider store={store}>
      <PdfPage
        featureToggles={featureToggles}
        pdfDocument={{
          pdfInfo: {
            numPages
          },
          getPage: jest.fn().mockImplementation(() => Promise.resolve({
            getViewport: () => ({ width: 100,
              height: 200 }),
            transport: {
              destroyed: false
            },
            getTextContent: jest.fn(),
            cleanup: jest.fn(),
            render: jest.fn()
          })),
          destroy: jest.fn(),
          _transport: {
            destroyed: false
          }
        }}
        file={documents[0].content_url}
        documentId={documents[0].id}
        pageIndex={2}
        documentType="Test"
        windowingOverscan=""
      />
    </Provider>
  ).dive();
};

describe('PdfPage', () => {
  describe('.render', () => {
    it('renders outer div', () => {
      const store = getStore();
      const wrapper = setUpPdfPage(store, featureToggles);

      expect(wrapper.find('.cf-pdf-pdfjs-container')).toHaveLength(1);
    });
  });

  describe('featureToggles are enabled', () => {
    beforeEach(() => {
      featureToggles.metricsPdfStorePages = true;
      const store = getStore();
      const wrapper = setUpPdfPage(store, featureToggles);

      wrapper.instance().componentDidMount();
    });
    it('metrics are stored and recorded', () => {
      const data = {
        overscan: "",
        documentType: "Test",
        pageCount: 3
      };

      expect(recordAsyncMetrics).toBeCalledWith();
      expect(storeMetrics).toHaveBeenCalledWith(
        documents[0].id,
        data,
        {
          message: 'pdf_page_render_time_in_ms',
          type: 'performance',
          product: 'reader',
          duration: 4
        }
      );
    });
  });

  describe('featureToggles are disabled', () => {
    it('metrics are not recorded and stored', () => {
      const store = getStore();
      featureToggles.metricsPdfStorePages = false;
      const wrapper = setUpPdfPage(store, featureToggles);
      recordAsyncMetrics.mockImplementationOnce(() => {
        throw new Error('Test Error!')
      });

      expect(storeMetrics).not.toBeCalled();
    });
  });
});
