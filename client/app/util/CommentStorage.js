import PDFJSAnnotate from 'pdf-annotate.js';
import ApiUtil from './ApiUtil';

export default class CommentStorage extends PDFJSAnnotate.StoreAdapter {
  getAnnotationByDocumentId = (documentId) => {
    return this.storedAnnotations[documentId] || [];
  }

  // TODO: What does this return if it's not found. Hopefully undefined.
  findAnnotation = (documentId, annotationId) => {
    let foundIndex = null;
    this.storedAnnotations[documentId].forEach((annotation, index) => {
      if (annotation.uuid.toString() === annotationId.toString()) {
        foundIndex = index;
      }
    });
    return foundIndex;
  }

  setOnCommentChange = (onCommentChange) => {
    this.onCommentChange = onCommentChange;
  }

  constructor(annotations) {
    super({
      getAnnotations: (documentId, pageNumber) => {
        return new Promise((resolve, reject) => {
          let allAnnotations = this.getAnnotationByDocumentId(documentId);
          let annotations = allAnnotations.filter((i) => {
            return i.page === pageNumber;
          });
          resolve({
            documentId,
            pageNumber,
            annotations});
        });
      },

      getAnnotation: (documentId, annotationId) => {
        return new Promise((resolve, reject) => {
          let annotations = this.getAnnotationByDocumentId(documentId);
          annotations.forEach((annotation) => {
            if (annotation.uuid.toString() === annotationId.toString()){
              resolve(annotation);
            }
          });
        });
      },

      addAnnotation: (documentId, pageNumber, annotation) => {
        return new Promise((resolve, reject) => {
          annotation.class = 'Annotation';
          annotation.page = pageNumber;
          annotation.documentId = documentId

          let annotations = this.getAnnotationByDocumentId(documentId);
          annotations.push(annotation);
          this.storedAnnotations[documentId] = annotations;
          let data = {annotation: ApiUtil.convertToSnakeCase(annotation)};
          ApiUtil.post(`/decision/annotation`, { data }).
            then((response) => {
              annotation.uuid = JSON.parse(response.text).id;
              resolve(annotation);
              this.onCommentChange();
            }, () => {
              reject();
            });
        });
      },

      editAnnotation: (documentId, annotationId, annotation) => {
        return new Promise((resolve, reject) => {
          let index = findAnnotation(documentId, annotationId);
          if (index === null) {
            reject();
          }
          this.storedAnnotations[documentId][index] = annotation;
          
          let data = {annotation: ApiUtil.convertToSnakeCase(annotation)};
          ApiUtil.patch(`/decision/annotation/${annotationId}`, { data }).
            then((response) => {
              resolve(annotation);
              this.onCommentChange();
            }, () => {
              reject();
            });
        });
      },

      deleteAnnotation: (documentId, annotationId) => {
        return new Promise((resolve, reject) => {
          let data = ApiUtil.convertToSnakeCase({ annotationId: annotationId });
          ApiUtil.delete(`/decision/annotation/${annotationId}`).
            then((response) => {
              let index = this.findAnnotation(documentId, annotationId);
              if (index !== null) {
                let annotations = this.storedAnnotations[documentId];
                annotations.splice(index, 1);
                this.storedAnnotations[documentId] = annotations;
                this.onCommentChange();
                resolve(true);
              } else {
                resolve(false);
              }
            }, () => {
              reject();
            });
        });
      },

      getComments: (documentId, annotationId) => {
        return new Promise((resolve, reject) => {
          resolve([]);
        });
      },

      addComment: (documentId, annotationId, content) => {
        return new Promise((resolve, reject) => {
          resolve([]);
        });
      },

      deleteComment: (documentId, commentId) => {
        return new Promise((resolve, reject) => {
          resolve([]);
        });
      }
    });

    this.storedAnnotations = {};
    annotations.forEach((annotation) => {
      annotation.uuid = annotation.id;
      annotation.class = "annotation";
      annotation.type = "point";
      annotation.documentId = annotation.document_id;

      if (!this.storedAnnotations[annotation.documentId]) {
        this.storedAnnotations[annotation.documentId] = [];
      }
      this.storedAnnotations[annotation.documentId].push(annotation);
    });

    this.onCommentChange = () => {};
  }
}



