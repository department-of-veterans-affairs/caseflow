import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { DocumentCategoryIcons } from '../../../app/components/DocumentCategoryIcons';

describe('DocumentCategoryIcons', () => {
  it('renders nothing when the document is not found', () => {
    const wrapper = mount(<DocumentCategoryIcons documents={{}} id={3} />);

    expect(wrapper.html()).to.equal(null);
  });

  it('renders no icons when the doc is not in any categories', () => {
    const documents = {
      3: {}
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(0);
  });

  it('renders an icon when the doc is in category_procedural', () => {
    const documents = {
      3: {
        category_procedural: true // eslint-disable-line camelcase
      }
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Procedural');
  });

  it('renders an icon when the doc is in category_other', () => {
    const documents = {
      3: {
        category_other: true // eslint-disable-line camelcase
      }
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Other Evidence');
  });

  it('renders an icon when the doc is in category_medical', () => {
    const documents = {
      3: {
        category_medical: true // eslint-disable-line camelcase
      }
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Medical');
  });

  it('renders three icons when the doc is in all categories', () => {
    const documents = {
      3: {
        category_medical: true, // eslint-disable-line camelcase
        category_procedural: true, // eslint-disable-line camelcase
        category_other: true // eslint-disable-line camelcase
      }
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(3);
  });
});
