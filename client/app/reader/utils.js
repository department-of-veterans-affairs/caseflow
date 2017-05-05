export const categoryFieldNameOfCategoryName =
    (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ x, y, page, documentId }) => [x, y, page, documentId].join('-');
