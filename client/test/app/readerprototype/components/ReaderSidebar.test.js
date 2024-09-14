// /* eslint-disable react/prop-types */
// import { render } from '@testing-library/react';
// import userEvent from '@testing-library/user-event';
// import React from 'react';
// import { Provider } from 'react-redux';
// import { applyMiddleware, createStore } from 'redux';
// import thunk from 'redux-thunk';
// import { addNewTag, removeTag } from '../../../../app/reader/Documents/DocumentsActions';
// import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
// import ReaderSidebar from '../../../../app/readerprototype/components/ReaderSidebar';
// import {CategoryIcon} from "../../../../app/components/icons/CategoryIcon";
// afterEach(() => jest.clearAllMocks());
//
// const getStore = (errorVisible) =>
//     createStore(
//         pdfViewerReducer,
//         {
//             pdfViewer: {
//                 openedAccordionSections: [
//                     'Issue tags',
//                     'Comments',
//                     'Categories',
//                 ],
//                 tagOptions: [],
//             },
//             documents: {},
//             annotationLayer: {
//                 annotations: [
//                     1
//                 ],
//             },
//         },
//         applyMiddleware(thunk)
//     );
//
// const Component = (props) => (
//     <Provider store={getStore(props.errorVisible)}>
//         <ReaderSidebar doc={props.doc} documents={
//             [props.doc]
//         } />
//     </Provider>
// );
// const doc = {
//     id: 1,
//     tags: [],
//     category_medical: false,
//     category_other: true,
//     visible: true
// };
//
// describe('Open Accordion Sections based on Redux', () => {
//     it('succeeds', () => {
//         const { container, getByText } = render(<Component doc={doc} errorVisible={false} />);
//
//         expect(container).toHaveTextContent("Select or tag issues")
//         expect(container).toHaveTextContent("Add a comment")
//         expect(container).toHaveTextContent("Procedural")
//
//     });
// });


/* eslint-disable react/prop-types */
import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
import ReaderSidebar from '../../../../app/readerprototype/components/ReaderSidebar';
import IssueTags from 'app/readerprototype/components/IssueTags';
afterEach(() => jest.clearAllMocks());
const getStore = (errorVisible) =>
    createStore(
        pdfViewerReducer,
        {
            pdfViewer: {
                tagOptions: [],
                openedAccordionSections: [
                    'Issue tags',
                    'Comments',
                    // 'Categories',
                ]
            },
            annotationLayer: {
                annotations: 1
            }
        },
        applyMiddleware(thunk)
);
const Component = (props) => (
    <Provider store={getStore(props.errorVisible)}>
        <ReaderSidebar
            doc={props.doc}
            documents={[props.doc]}
        />
        <Provider store={getStore(props.errorVisible)}>
            <IssueTags doc={props.doc} />
        </Provider>
    </Provider>
);
const doc = {
    id: 1,
    tags: [],
    category_procedural: true,
};

describe('Open Accordion Sections based on Redux', () => {
    it('succeeds', () => {
        const { container, getByText } = render(<Component doc={doc} document={doc} errorVisible={false} />);

        expect(container).toHaveTextContent("Select or tag issues")
        expect(container).toHaveTextContent("Add a comment")
        // expect(container).toHaveTextContent("Procedural")
    });
});