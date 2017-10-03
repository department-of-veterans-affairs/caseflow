import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import sinon from 'sinon';
import XhrStub from '../../helpers/XhrStub';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

import { PdfPage, getSquaredDistanceToCenter, shouldDrawPage } from '../../../app/reader/PdfPage';

describe('PdfPage', () => {
  // describe('getSquaredDistanceToCenter', () => {
  //   it()
  // });

  const getDocument = async () => {
    const data = atob(
      'JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwog' +
      'IC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAv' +
      'TWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0K' +
      'Pj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAg' +
      'L1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+' +
      'PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9u' +
      'dAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2Jq' +
      'Cgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJU' +
      'CjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVu' +
      'ZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4g' +
      'CjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAw' +
      'MDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9v' +
      'dCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G');

    return await PDFJS.getDocument({ data });
  }

  const FILE_NAME = 'test';
  const PAGE_INDEX = 0;

  const getContext = async (props) => {
    const pdfDocument = await getDocument();

    return shallow(<PdfPage
      pdfDocument={pdfDocument}
      pageIndex={PAGE_INDEX}
      file={FILE_NAME}
      {...props}
    />)
  }

  const sleep = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  describe('When page is visible', async () => {
    it('setUpPdfPage is called', async () => {
      const setUpPdfPage = sinon.spy()
      const pdfPage = await getContext({
        setUpPdfPage,
        isVisible: true
      });

      await sleep(0);
      // TODO: Put more in matcher
      expect(setUpPdfPage.withArgs(FILE_NAME, PAGE_INDEX).calledOnce).to.equal(true);
    });

    it.only('drawPage is called', async () => {
      const pdfPage = await getContext({
        isVisible: true
      });
      pdfPage.setProps({
        page: 'test'
      });
    })
  });
});
