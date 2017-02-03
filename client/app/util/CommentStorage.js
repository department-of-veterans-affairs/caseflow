import PDFJSAnnotate from 'pdf-annotate.js';

export default class CommentStorage extends PDFJSAnnotate.StoreAdapter {
  constructor() {
    super({
      getAnnotations(documentId, pageNumber) {
        return new Promise((resolve, reject) => {
          let annotations = getAnnotations(documentId).filter((i) => {
            return i.page === pageNumber && i.class === 'Annotation';
          });

          resolve({
            documentId,
            pageNumber,
            annotations
          });
        });
      },

      getAnnotation(documentId, annotationId) {
        return Promise.resolve(getAnnotations(documentId)[findAnnotation(documentId, annotationId)]);
      },

      addAnnotation(documentId, pageNumber, annotation) {
        return new Promise((resolve, reject) => {
          annotation.class = 'Annotation';
          annotation.uuid = generateUUID();
          annotation.page = pageNumber;

          let annotations = getAnnotations(documentId);
          annotations.push(annotation);
          updateAnnotations(documentId, annotations);

          resolve(annotation);
        });
      },

      editAnnotation(documentId, annotationId, annotation) {
        return new Promise((resolve, reject) => {
          let annotations = getAnnotations(documentId);
          annotations[findAnnotation(documentId, annotationId)] = annotation;
          updateAnnotations(documentId, annotations);

          resolve(annotation);
        });
      },

      deleteAnnotation(documentId, annotationId) {
        return new Promise((resolve, reject) => {
          let index = findAnnotation(documentId, annotationId);
          if (index > -1) {
            let annotations = getAnnotations(documentId);
            annotations.splice(index, 1);
            updateAnnotations(documentId, annotations);
          }

          resolve(true);
        });
      },

      getComments(documentId, annotationId) {
        return new Promise((resolve, reject) => {
          resolve(getAnnotations(documentId).filter((i) => {
            return i.class === 'Comment' && i.annotation === annotationId;
          }));
        });
      },

      addComment(documentId, annotationId, content) {
        return new Promise((resolve, reject) => {
          let comment = {
            class: 'Comment',
            uuid: generateUUID(),
            annotation: annotationId,
            content: content
          };

          let annotations = getAnnotations(documentId);
          annotations.push(comment);
          updateAnnotations(documentId, annotations);

          resolve(comment);
        });
      },

      deleteComment(documentId, commentId) {
        return new Promise((resolve, reject) => {
          getAnnotations(documentId);
          let index = -1;
          let annotations = getAnnotations(documentId);
          for (let i=0, l=annotations.length; i<l; i++) {
            if (annotations[i].uuid === commentId) {
              index = i;
              break;
            }
          }

          if (index > -1) {
            annotations.splice(index, 1);
            updateAnnotations(documentId, annotations);
          }

          resolve(true);
        });
      }
    });
  }
}

let storedAnnotations = {};

/* eslint-disable no-bitwise */
/* eslint-disable no-mixed-operators */
/* From http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript */
let generateUUID = function() {
  let date = new Date().getTime();
  let uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (character) => {
    let random = (date + Math.random() * 16) % 16 | 0;

    date = Math.floor(date / 16);

    return (character === 'x' ? random : random & 0x3 | 0x8).toString(16);
  });

  return uuid;
};

/* eslint-enable no-bitwise */
/* eslint-enable no-mixed-operators */

getAnnotations(documentId) {
  return storedAnnotations[documentId];
}

updateAnnotations(documentId, annotations) {
  storedAnnotations[documentId] = annotations;
}

findAnnotation(documentId, annotationId) {
  let index = -1;
  let annotations = getAnnotations(documentId);
  for (let i=0, l=annotations.length; i<l; i++) {
    if (annotations[i].uuid === annotationId) {
      index = i;
      break;
    }
  }
  return index;
}

