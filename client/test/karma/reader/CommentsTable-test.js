import { expect } from 'chai';
import { getRowObjects } from '../../../app/reader/CommentsTable';

describe('CommentsTable', () => {
  it('in comments mode, only adds comment rows', () => {
    const documents = [
      {
        id: 12,
        type: 'SOC',
        serialized_receipt_date: '2017-06-05'
      },
      {
        id: 15,
        type: 'NOD',
        serialized_receipt_date: '2016-10-23'
      },
      {
        id: 20,
        type: 'Form 9',
        serialized_receipt_date: '2018-02-01'
      }
    ];
    const annotationsPerDocument = {
      12: [{
        comment: 'Hello World!',
        documentId: 12,
        relevant_date: null
      }],
      15: [{
        comment: 'This is an example comment',
        documentId: 15,
        relevant_date: '2018-05-05'
      }],
      20: []
    };
    const rowObjects = getRowObjects(documents, annotationsPerDocument);

    expect(rowObjects).to.deep.equal([
      {
        documentId: 15,
        comment: 'This is an example comment',
        relevant_date: '2018-05-05',
        serialized_receipt_date: '2016-10-23',
        docType: 'NOD'
      },
      {
        comment: 'Hello World!',
        documentId: 12,
        relevant_date: null,
        serialized_receipt_date: '2017-06-05',
        docType: 'SOC'
      }
    ]);
  });
});
