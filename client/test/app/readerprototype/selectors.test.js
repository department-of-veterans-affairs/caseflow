import { tagErrorSelector, tagSelector } from '../../../app/readerprototype/selectors';

describe('tagErrorSelector', () => {
  it('handles no error', () => {
    const state = {
      pdfViewer: {},
    };

    expect(() => tagErrorSelector(state)).not.toThrowError();
  });

  it('handles no tag', () => {
    const state = {
      pdfViewer: { pdfSideBarError: {} },
    };

    expect(() => tagErrorSelector(state)).not.toThrowError();
  });

  it('returns error visibility', () => {
    const state = {
      pdfViewer: { pdfSideBarError: { tag: { visible: true } } },
    };

    expect(tagErrorSelector(state)).toBeTruthy();
  });
});

describe('tagSelector', () => {
  it('returns tag options', () => {
    const state = {
      pdfViewer: {
        tagOptions: [{ id: 1, text: 'Service Related' }],
      },
    };

    expect(tagSelector(state)).toEqual([{ id: 1, text: 'Service Related' }]);
  });
});
