desc "clean old form files and mark future form files for cleaning"
task cleanforms: :environment do
  Form8PdfService.clean
  Form8PdfService.mark_for_clean
end
