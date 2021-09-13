| [Tasks Overview](tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docs-DR/tasklist.md) | [ES tasks](../docs-ES/tasklist.md) | [H tasks](../docs-H/tasklist.md) |

# TranscriptionTask_Organization Description

Task stats [for DR](../docs-DR/TranscriptionTask_Organization.md), [for ES](../docs-ES/TranscriptionTask_Organization.md), [for H](../docs-H/TranscriptionTask_Organization.md) dockets.

See [Transcription / Evidence Submission](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#4-transcription--evidence-submission).

<!-- class_comments:begin -->
<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->
Code comments extracted from Ruby file:
* Task to either confirm the completion of the hearing transcription or reschedule the hearing.
  
* If there's a problem with the hearing recording, the veteran/appellant is usually notified.
* Veterans/Appllants can choose to continue with partial or no transcrition or ask to be
  scheduled for a new hearing.
  
* When marked as Transcribed, the appeal will be released to a judge for review but the
* EvidenceSubmissionWindowTask will stay open if there is one for the appeal.
  
* This task is only only applicable to AMA appeals in caseflow
<!-- class_comments:end -->
