import PDFJSAnnotate from 'pdf-annotate.js';
import ApiUtil from './ApiUtil';

export default class CommentStorage extends PDFJSAnnotate.StoreAdapter {
  constructor() {
    super({
      getAnnotations(documentId, pageNumber) {
        return new Promise((resolve, reject) => {
          getAnnotations(documentId).
            then((allAnnotations) => {
              let annotations = allAnnotations.filter((i) => {
                return i.page === pageNumber;
              });
              resolve({
                documentId,
                pageNumber,
                annotations});
            }, () => { 
              reject()
            });
        });
      },

      getAnnotation(documentId, annotationId) {
        return new Promise((resolve, reject) => {
          getAnnotations(documentId).
            then((annotations) => {
              annotations.forEach((annotation) => {
                if (annotation.uuid === annotationId){
                  resolve(annotation);
                }
              });
              reject();
            }, () => { 
              reject()
            });
        });
      },

      addAnnotation(documentId, pageNumber, annotation) {
        return new Promise((resolve, reject) => {
          annotation.class = 'Annotation';
          annotation.page = pageNumber;
          annotation.documentId = documentId

          getAnnotations(documentId).then((annotations) => {
            annotations.push(annotation);
            updateAnnotations(documentId, annotations);
            let data = {annotation: ApiUtil.convertToSnakeCase(annotation)};
            ApiUtil.post(`/decision/review/add_annotation`, { data }).
              then((response) => {
                annotation.uuid = JSON.parse(response.text).id;
                resolve(annotation);
              }, () => {
                reject();
              });
          });
          
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
          debugger;
          let data = ApiUtil.convertToSnakeCase({ annotation_id: annotationId });
          ApiUtil.delete(`/decision/review/delete_annotation`, { data }).
            then((response) => {
              let index = findAnnotation(documentId, annotationId);
              if (index) {
                let annotations = storedAnnotations[documentId];
                annotations.splice(index, 1);
                updateAnnotations(documentId, annotations);
              }
              resolve();
            }, () => {
              reject();
            });
          resolve(true);
        });
      },

      getComments(documentId, annotationId) {
        return new Promise((resolve, reject) => {
          resolve([]);
        });
      },

      addComment(documentId, annotationId, content) {
        return new Promise((resolve, reject) => {
          resolve([]);
        });
      },

      deleteComment(documentId, commentId) {
        return new Promise((resolve, reject) => {
          resolve([]);
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

let getAnnotations = (documentId) => {
  return new Promise((resolve, reject) => {
    if (!storedAnnotations[documentId]) {
      let query = ApiUtil.convertToSnakeCase({documentId: documentId});
      ApiUtil.get(`/decision/review/get_annotations`, { query }).
        then((response) => {
          storedAnnotations[documentId] = JSON.parse(response.text).annotations;
          storedAnnotations[documentId].forEach((annotation) => {
            annotation.uuid = annotation.id;
            annotation.class = "annotation";
            annotation.type = "point";
            annotation.x = annotation.x_location;
            annotation.y = annotation.y_location;
          });
          resolve(storedAnnotations[documentId])
        }, (error) => {
          console.log('error retrieving annotations');
          console.log(error);
          reject();
        });
    } else {
      resolve(storedAnnotations[documentId]);
    } 
  });
}

let updateAnnotations = (documentId, annotations) => {
  storedAnnotations[documentId] = annotations;
}

// TODO: What does this return if it's not found. Hopefully undefined.
let findAnnotation = (documentId, annotationId) => {
  return storedAnnotations[documentId] ((annotation, index) => {
    if (annotation.uuid === annotationId) {
      return index;
    }
  });
}

