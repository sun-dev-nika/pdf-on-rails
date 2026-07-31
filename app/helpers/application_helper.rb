module ApplicationHelper
  # ProcessedFile#operation matches a key under either pdf_operations.nav or
  # conversions.nav depending which controller created it (OCR/organize live
  # under the former, Office->PDF under the latter).
  def operation_label(operation)
    t("pdf_operations.nav.#{operation}", default: t("conversions.nav.#{operation}", default: operation))
  end
end
