import PDFJSAnnotate from 'pdf-annotate.js';
import ApiUtil from './ApiUtil';

export default class CommentStorage extends PDFJSAnnotate.StoreAdapter {
  constructor(generateComments = () => {}) {
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
                if (annotation.uuid.toString() === annotationId.toString()){
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
            storedAnnotations[documentId] = annotations;
            let data = {annotation: ApiUtil.convertToSnakeCase(annotation)};
            ApiUtil.post(`/decision/review/add_annotation`, { data }).
              then((response) => {
                annotation.uuid = JSON.parse(response.text).id;
                resolve(annotation);
                generateComments();
              }, () => {
                reject();
              });
          });
          
        });
      },

      editAnnotation(documentId, annotationId, annotation) {
        return new Promise((resolve, reject) => {
          let index = findAnnotation(documentId, annotationId);
          if (index === null) {
            reject();
          }
          storedAnnotations[documentId][index] = annotation;
          
          let data = {annotation: ApiUtil.convertToSnakeCase(annotation)};
          ApiUtil.patch(`/decision/review/update_annotation`, { data }).
            then((response) => {
              resolve(annotation);
              generateComments();
            }, () => {
              reject();
            });
        });
      },

      deleteAnnotation(documentId, annotationId) {
        return new Promise((resolve, reject) => {
          let data = ApiUtil.convertToSnakeCase({ annotationId: annotationId });
          ApiUtil.delete(`/decision/review/delete_annotation`, { data }).
            then((response) => {
              let index = findAnnotation(documentId, annotationId);
              if (index !== null) {
                let annotations = storedAnnotations[documentId];
                annotations.splice(index, 1);
                storedAnnotations[documentId] = annotations;
                generateComments();
                resolve(true);
              } else {
                resolve(false);
              }
            }, () => {
              reject();
            });
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

// TODO: What does this return if it's not found. Hopefully undefined.
let findAnnotation = (documentId, annotationId) => {
  let foundIndex = null;
  storedAnnotations[documentId].forEach((annotation, index) => {
    if (annotation.uuid.toString() === annotationId.toString()) {
      foundIndex = index;
    }
  });
  return foundIndex;
}

