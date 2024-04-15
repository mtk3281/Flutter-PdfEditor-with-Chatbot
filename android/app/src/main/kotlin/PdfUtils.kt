// PdfUtils.kt

import com.itextpdf.text.Document
import com.itextpdf.text.pdf.PdfCopy
import com.itextpdf.text.pdf.PdfReader
import java.io.FileOutputStream

fun combinePdfFiles(pdfPaths: List<String>, combinedPdfPath: String) {
    val document = Document()
    val copy = PdfCopy(document, FileOutputStream(combinedPdfPath))
    document.open()

    for (pdfPath in pdfPaths) {
        val reader = PdfReader(pdfPath)
        copy.addDocument(reader)
        reader.close()
    }

    document.close()
}
