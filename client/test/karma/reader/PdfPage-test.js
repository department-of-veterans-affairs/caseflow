import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import sinon from 'sinon';
import XhrStub from '../../helpers/XhrStub';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { createStore, applyMiddleware, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import readerReducer from '../../../app/reader/reducer';

import { PdfPage, PAGE_MARGIN_BOTTOM } from '../../../app/reader/PdfPage';

describe('PdfPage', () => {
  // describe('getSquaredDistanceToCenter', () => {
  //   it()
  // });
  const getStore = () => {
    return createStore(combineReducers({
      readerReducer
    }), applyMiddleware(thunk));
  }

  const getDocument = async () => {
    // const data = atob(
    //   'JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwog' +
    //   'IC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAv' +
    //   'TWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0K' +
    //   'Pj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAg' +
    //   'L1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+' +
    //   'PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9u' +
    //   'dAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2Jq' +
    //   'Cgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJU' +
    //   'CjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVu' +
    //   'ZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4g' +
    //   'CjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAw' +
    //   'MDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9v' +
    //   'dCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G');

    const data = atob('JVBERi0xLjcNCg0KMSAwIG9iaiAgJSBlbnRyeSBwb2ludA0KPDwNCiAgL1R5' +
      'cGUgL0NhdGFsb2cNCiAgL1BhZ2VzIDIgMCBSDQo+Pg0KZW5kb2JqDQoNCjIgMCBvYmoNCjw8DQog' +
      'IC9UeXBlIC9QYWdlcw0KICAvTWVkaWFCb3ggWyAwIDAgMjAwIDQwMCBdDQogIC9Db3VudCAxDQog' +
      'IC9LaWRzIFsgMyAwIFIgXQ0KPj4NCmVuZG9iag0KDQozIDAgb2JqDQo8PA0KICAvVHlwZSAvUGFn' +
      'ZQ0KICAvUGFyZW50IDIgMCBSDQogIC9SZXNvdXJjZXMgPDwNCiAgICAvRm9udCA8PA0KICAgICAg' +
      'L0YxIDQgMCBSIA0KICAgID4+DQogID4+DQogIC9Db250ZW50cyA1IDAgUg0KPj4NCmVuZG9iag0K' +
      'DQo0IDAgb2JqDQo8PA0KICAvVHlwZSAvRm9udA0KICAvU3VidHlwZSAvVHlwZTENCiAgL0Jhc2VG' +
      'b250IC9UaW1lcy1Sb21hbg0KPj4NCmVuZG9iag0KDQo1IDAgb2JqICAlIHBhZ2UgY29udGVudA0K' +
      'PDwNCiAgL0xlbmd0aCA0NA0KPj4NCnN0cmVhbQ0KQlQNCjcwIDUwIFREDQovRjEgMTIgVGYNCihI' +
      'ZWxsbywgd29ybGQhKSBUag0KRVQNCmVuZHN0cmVhbQ0KZW5kb2JqDQoNCnhyZWYNCjAgNg0KMDAw' +
      'MDAwMDAwMCA2NTUzNSBmIA0KMDAwMDAwMDAxMCAwMDAwMCBuIA0KMDAwMDAwMDA3OSAwMDAwMCBu' +
      'IA0KMDAwMDAwMDE3MyAwMDAwMCBuIA0KMDAwMDAwMDMwMSAwMDAwMCBuIA0KMDAwMDAwMDM4MCAw' +
      'MDAwMCBuIA0KdHJhaWxlcg0KPDwNCiAgL1NpemUgNg0KICAvUm9vdCAxIDAgUg0KPj4NCnN0YXJ0' +
      'eHJlZg0KNDkyDQolJUVPRg==');

    return await PDFJS.getDocument({ data });
  }

  const FILE_NAME = 'test';
  const PAGE_INDEX = 0;
  const PAGE_WIDTH = 200;

  const getContext = async (props) => {
    const pdfDocument = await getDocument();

    return shallow(<PdfPage
        pdfDocument={pdfDocument}
        pageIndex={PAGE_INDEX}
        file={FILE_NAME}
        {...props}
      />);
  }

  const sleep = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  describe('When page is visible', async () => {
    it.only('setUpPdfPage is called', async () => {
      const setUpPdfPage = sinon.spy()
      const pdfPage = await getContext({
        setUpPdfPage,
        isVisible: true
      });

      await sleep(0);
      // TODO: Put more in matcher
      expect(setUpPdfPage.withArgs(FILE_NAME, PAGE_INDEX).calledOnce).to.equal(true);
    });

    it('text is drawn', async () => {
      const pdfPage = await getContext({
        isVisible: true,
        scrollWindowCenter: {
          x: 0,
          y: 0
        }
      });

      await sleep(0);

      expect(pdfPage.find('.textLayer').first().text()).to.equal('Hello, world!');
    });

    it('canvas is drawn', async () => {
      const pdfPage = await getContext({
        isVisible: true,
        scrollWindowCenter: {
          x: 0,
          y: 0
        }
      });

      await sleep(0);
      console.log(pdfPage.debug());

      // console.log(pdfPage.find('.canvasWrapper').html());
    });

    [1, 2].forEach((scale) => {
      it(`page is rendered with correct dimensions at scale ${scale}`, async () => {
        const pdfPage = await getContext({
          isVisible: true,
          scale
        });

        await sleep(0);
        pdfPage.update();

        const style = pdfPage.find('.cf-pdf-pdfjs-container').first().prop('style');

        expect(style.marginBottom).to.equal(`${PAGE_MARGIN_BOTTOM * scale}px`);
        expect(style.width).to.equal(`${PAGE_WIDTH * scale}px`);
      });
    });

    [90, 180, 270].forEach((rotation) => {
      it.only(`page is rendered with correct transform at rotation ${rotation}`, async () => {
        const pdfPage = await getContext({
          isVisible: true,
          scale: 1,
          rotation
        });

        await sleep(0);
        // pdfPage.update();
        // console.log(pdfPage.html());

        const style = pdfPage.find('#rotationDiv1').first().prop('style');

        expect(style.transform).to.equal(`rotate(${rotation}deg)`);
      });
    });
  });
});
